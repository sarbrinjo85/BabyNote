import 'package:flutter/material.dart';
import '../../../core/widgets/baby_loading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../child/presentation/child_providers.dart';
import '../../child/presentation/selected_child_provider.dart';
import '../domain/formula_brand_presets.dart';
import '../domain/formula_inventory.dart';
import 'formula_inventory_providers.dart';

class FormulaInventoryRegisterPage extends ConsumerStatefulWidget {
  const FormulaInventoryRegisterPage({super.key, this.editing});

  final FormulaInventory? editing;

  @override
  ConsumerState<FormulaInventoryRegisterPage> createState() =>
      _FormulaInventoryRegisterPageState();
}

class _FormulaInventoryRegisterPageState
    extends ConsumerState<FormulaInventoryRegisterPage> {
  final _formKey = GlobalKey<FormState>();

  late FormulaForm _form;
  late String _productName;
  late String _brand;
  late String _containerAmount; // powder=g, liquid=ml
  late String _gPerScoop;
  late String _mlPerScoop;
  late String _priceWon;
  late String _store;
  DateTime? _purchasedAt;
  DateTime? _openedAt;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _form = e?.form ?? FormulaForm.liquid;
    _productName = e?.productName ?? '';
    _brand = e?.brand ?? '';
    _containerAmount = e?.containerGrams.toString() ?? '';
    _gPerScoop = (e?.gPerScoop ?? 4.4).toString();
    _mlPerScoop = (e?.mlPerScoop ?? 30.0).toString();
    _priceWon = e?.priceMinor?.toString() ?? '';
    _store = e?.store ?? '';
    _purchasedAt = e?.purchasedAt;
    _openedAt = e?.openedAt;
  }

  Future<void> _pickDate({
    required String label,
    required DateTime? current,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      helpText: label,
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _submit(String childId) async {
    final l10n = AppLocalizations.of(context);
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    form.save();

    final amount = int.tryParse(_containerAmount)!;
    final price = int.tryParse(_priceWon);
    final gps = double.tryParse(_gPerScoop) ?? 4.4;
    final mps = double.tryParse(_mlPerScoop) ?? 30.0;

    if (_isEdit) {
      await ref.read(formulaInventoryControllerProvider.notifier).saveEdit(
            childId: childId,
            id: widget.editing!.id,
            productName: _productName.trim(),
            brand: _brand.trim().isEmpty ? null : _brand.trim(),
            form: _form,
            containerGrams: amount,
            gPerScoop: gps,
            mlPerScoop: mps,
            purchasedAt: _purchasedAt,
            priceMinor: price,
            store: _store.trim().isEmpty ? null : _store.trim(),
            openedAt: _openedAt,
          );
    } else {
      await ref.read(formulaInventoryControllerProvider.notifier).create(
            childId: childId,
            productName: _productName.trim(),
            brand: _brand.trim().isEmpty ? null : _brand.trim(),
            form: _form,
            containerGrams: amount,
            gPerScoop: gps,
            mlPerScoop: mps,
            purchasedAt: _purchasedAt,
            priceMinor: price,
            store: _store.trim().isEmpty ? null : _store.trim(),
            openedAt: _openedAt,
          );
    }

    if (!mounted) return;
    final state = ref.read(formulaInventoryControllerProvider);
    state.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? l10n.recordEditSaved : l10n.formulaSavedToast)),
        );
        context.pop();
      },
      loading: () {},
      error: (err, _) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.errorFailed(err))));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final asyncChildren = ref.watch(myChildrenProvider);
    final asyncCtrl = ref.watch(formulaInventoryControllerProvider);
    final isLoading = asyncCtrl.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.formulaEditTitle : l10n.formulaRegisterTitle),
      ),
      body: asyncChildren.when(
        loading: () => const Center(child: BabyLoading()),
        error: (err, _) => Center(child: Text(l10n.errorChildrenLoadFailed(err))),
        data: (children) {
          if (children.isEmpty) return _NoChildPlaceholder();
          final child = _isEdit
              ? children.firstWhere(
                  (c) => c.id == widget.editing!.childId,
                  orElse: () => children.first,
                )
              : (ref.watch(selectedChildProvider) ?? children.first);

          return SafeArea(
            top: false,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(Spacing.md),
                children: [
                  Row(
                    children: [
                      const Icon(Icons.child_care),
                      const SizedBox(width: Spacing.xs),
                      Text(child.name,
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),

                  // ── 형태 선택 ──────────────────────────────────────
                  Text('분유 형태', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: Spacing.xs),
                  SegmentedButton<FormulaForm>(
                    segments: const [
                      ButtonSegment(
                        value: FormulaForm.powder,
                        label: Text('가루분유'),
                        icon: Icon(Icons.scatter_plot_outlined),
                      ),
                      ButtonSegment(
                        value: FormulaForm.liquid,
                        label: Text('액상분유'),
                        icon: Icon(Icons.local_drink_outlined),
                      ),
                    ],
                    selected: {_form},
                    onSelectionChanged: (s) => setState(() => _form = s.first),
                  ),
                  const SizedBox(height: Spacing.lg),

                  TextFormField(
                    initialValue: _productName,
                    decoration: InputDecoration(
                      labelText: l10n.formulaProductName,
                      hintText: l10n.formulaProductHint,
                    ),
                    autofocus: !_isEdit,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? l10n.formulaProductRequired : null,
                    onSaved: (v) => _productName = v ?? '',
                  ),
                  const SizedBox(height: Spacing.md),

                  // ── 브랜드 (가루는 프리셋, 액상은 자유 입력) ────────
                  if (_form == FormulaForm.powder)
                    _BrandPresetField(
                      initial: _brand,
                      onChanged: (val, preset) {
                        setState(() {
                          _brand = val;
                          if (preset != null) {
                            _gPerScoop = preset.gPerScoop.toString();
                            _mlPerScoop = preset.mlPerScoop.toString();
                          }
                        });
                      },
                    )
                  else
                    TextFormField(
                      initialValue: _brand,
                      decoration: InputDecoration(
                        labelText: l10n.formulaBrandLabel,
                        hintText: l10n.formulaBrandHint,
                      ),
                      onSaved: (v) => _brand = v ?? '',
                    ),
                  const SizedBox(height: Spacing.md),

                  // ── 용량 (가루: g / 액상: ml) ────────────────────
                  TextFormField(
                    initialValue: _containerAmount,
                    decoration: InputDecoration(
                      labelText: _form == FormulaForm.powder
                          ? '1통 무게 (가루)'
                          : '1팩/병 용량 (액상)',
                      hintText: _form == FormulaForm.powder ? '예: 800' : '예: 200',
                      suffixText: _form == FormulaForm.powder ? 'g' : 'ml',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return l10n.formulaCapacityRequired;
                      final n = int.tryParse(v);
                      if (n == null || n <= 0) return l10n.commonPositiveOnly;
                      if (n > 10000) return l10n.formulaCapacityTooLarge;
                      return null;
                    },
                    onSaved: (v) => _containerAmount = v ?? '',
                  ),
                  const SizedBox(height: Spacing.md),

                  // ── 가루분유 전용: 1스쿱 정보 ──────────────────────
                  if (_form == FormulaForm.powder) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _gPerScoop,
                            decoration: const InputDecoration(
                              labelText: '1스쿱 무게',
                              suffixText: 'g',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            onSaved: (v) =>
                                _gPerScoop = v ?? '4.4',
                          ),
                        ),
                        const SizedBox(width: Spacing.md),
                        Expanded(
                          child: TextFormField(
                            initialValue: _mlPerScoop,
                            decoration: const InputDecoration(
                              labelText: '1스쿱 분유',
                              suffixText: 'ml',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            onSaved: (v) =>
                                _mlPerScoop = v ?? '30',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      '브랜드 선택 시 자동 채워집니다. 라벨 보고 수정 가능.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: Spacing.md),
                  ],

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.formulaPurchaseDateOptional),
                    subtitle: Text(_purchasedAt == null
                        ? l10n.commonTapToSelect
                        : _formatDate(_purchasedAt!)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _pickDate(
                      label: l10n.formulaPurchaseDateLabel,
                      current: _purchasedAt,
                      onPicked: (d) => setState(() => _purchasedAt = d),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.formulaOpenedDateOptional),
                    subtitle: Text(_openedAt == null
                        ? l10n.formulaNotOpenedYet
                        : _formatDate(_openedAt!)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _pickDate(
                      label: l10n.formulaOpenedDateLabel,
                      current: _openedAt,
                      onPicked: (d) => setState(() => _openedAt = d),
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: Spacing.md),

                  TextFormField(
                    initialValue: _priceWon,
                    decoration: InputDecoration(
                      labelText: l10n.formulaPriceLabel,
                      hintText: l10n.formulaPriceHint,
                      suffixText: l10n.formulaPriceUnit,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final n = int.tryParse(v);
                      if (n == null || n < 0) return l10n.commonPositiveOnly;
                      return null;
                    },
                    onSaved: (v) => _priceWon = v ?? '',
                  ),
                  const SizedBox(height: Spacing.md),
                  TextFormField(
                    initialValue: _store,
                    decoration: InputDecoration(
                      labelText: l10n.formulaShopLabel,
                      hintText: l10n.formulaShopHint,
                    ),
                    onSaved: (v) => _store = v ?? '',
                  ),

                  const SizedBox(height: Spacing.xl),
                  FilledButton.icon(
                    onPressed: isLoading ? null : () => _submit(child.id),
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(isLoading
                        ? l10n.commonSaving
                        : (_isEdit ? l10n.commonSave : l10n.commonRegister)),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(TouchTarget.huge),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }
}

/// 가루분유 브랜드 입력 — 프리셋 드롭다운 + 자유 입력 결합.
///
/// Autocomplete 대신 DropdownMenu + 텍스트 필드 hybrid: 사용자가
/// 직접 친 값도 onSaved로 저장 가능.
class _BrandPresetField extends StatefulWidget {
  const _BrandPresetField({
    required this.initial,
    required this.onChanged,
  });
  final String initial;
  final void Function(String value, FormulaBrandPreset? matched) onChanged;

  @override
  State<_BrandPresetField> createState() => _BrandPresetFieldState();
}

class _BrandPresetFieldState extends State<_BrandPresetField> {
  late TextEditingController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _ctrl,
          decoration: const InputDecoration(
            labelText: '브랜드',
            hintText: '예: 매일 앱솔루트',
          ),
          onChanged: (v) {
            final preset = kFormulaBrandPresets[v];
            widget.onChanged(v, preset);
          },
        ),
        const SizedBox(height: Spacing.xs),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final entry in kFormulaBrandPresets.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    label: Text(entry.key),
                    onPressed: () {
                      _ctrl.text = entry.key;
                      widget.onChanged(entry.key, entry.value);
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoChildPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.child_friendly, size: 48),
            const SizedBox(height: Spacing.sm),
            Text(l10n.commonRegisterChildFirst),
            const SizedBox(height: Spacing.md),
            FilledButton.icon(
              onPressed: () {
                context.pop();
                context.push('/child/new');
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.commonGoRegisterChild),
            ),
          ],
        ),
      ),
    );
  }
}
