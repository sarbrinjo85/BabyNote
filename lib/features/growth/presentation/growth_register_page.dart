import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/child_picker_action.dart';
import '../../child/presentation/child_providers.dart';
import '../../child/presentation/selected_child_provider.dart';
import '../domain/growth.dart';
import 'growth_providers.dart';

/// 성장 측정 화면 (체중/키/머리둘레). 등록 + 편집 통합.
class GrowthRegisterPage extends ConsumerStatefulWidget {
  const GrowthRegisterPage({super.key, this.editing});

  final Growth? editing;

  @override
  ConsumerState<GrowthRegisterPage> createState() =>
      _GrowthRegisterPageState();
}

class _GrowthRegisterPageState extends ConsumerState<GrowthRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _measuredAt;
  late String _weightKg;
  late String _heightCm;
  late String _headCm;
  late String _note;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _measuredAt = e?.measuredAt ?? DateTime.now();
    _weightKg = e?.weightG != null
        ? (e!.weightG! / 1000).toStringAsFixed(2)
        : '';
    _heightCm = e?.heightMm != null
        ? (e!.heightMm! / 10).toStringAsFixed(1)
        : '';
    _headCm = e?.headCircumferenceMm != null
        ? (e!.headCircumferenceMm! / 10).toStringAsFixed(1)
        : '';
    _note = e?.note ?? '';
  }

  Future<void> _pickDate() async {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _measuredAt,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      helpText: l10n.growthDateHelp,
    );
    if (picked != null) {
      setState(() => _measuredAt = picked);
    }
  }

  Future<void> _submit(String childId) async {
    final l10n = AppLocalizations.of(context);
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    form.save();

    final w = double.tryParse(_weightKg);
    final h = double.tryParse(_heightCm);
    final hd = double.tryParse(_headCm);

    if (w == null && h == null && hd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.growthAtLeastOneRequired)),
      );
      return;
    }

    if (_isEdit) {
      await ref.read(growthCreationControllerProvider.notifier).saveEdit(
            childId: childId,
            id: widget.editing!.id,
            measuredAt: _measuredAt,
            weightG: w == null ? null : (w * 1000).round(),
            heightMm: h == null ? null : (h * 10).round(),
            headCircumferenceMm: hd == null ? null : (hd * 10).round(),
            note: _note.trim().isEmpty ? null : _note.trim(),
          );
    } else {
      await ref.read(growthCreationControllerProvider.notifier).create(
            childId: childId,
            measuredAt: _measuredAt,
            weightG: w == null ? null : (w * 1000).round(),
            heightMm: h == null ? null : (h * 10).round(),
            headCircumferenceMm: hd == null ? null : (hd * 10).round(),
            note: _note.trim().isEmpty ? null : _note.trim(),
          );
    }

    if (!mounted) return;
    final state = ref.read(growthCreationControllerProvider);
    state.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? l10n.recordEditSaved : l10n.growthSavedToast)),
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
    final asyncCtrl = ref.watch(growthCreationControllerProvider);
    final isLoading = asyncCtrl.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.growthEditTitle : l10n.growthTitle),
        actions: _isEdit ? null : const [ChildPickerAction()],
      ),
      body: asyncChildren.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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

                  // ── 측정일 ─────────────────────────────────────
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.growthDateLabel),
                    subtitle: Text(_formatDate(_measuredAt)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _pickDate,
                  ),
                  const Divider(),
                  const SizedBox(height: Spacing.md),

                  // ── 체중 ───────────────────────────────────────
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: l10n.growthWeightLabel,
                      hintText: l10n.growthWeightHint,
                      suffixText: 'kg',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => _validateRange(l10n, v, 0.5, 30, 'kg'),
                    onSaved: (v) => _weightKg = v ?? '',
                  ),
                  const SizedBox(height: Spacing.md),

                  // ── 키 ─────────────────────────────────────────
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: l10n.growthHeightLabel,
                      hintText: l10n.growthHeightHint,
                      suffixText: 'cm',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => _validateRange(l10n, v, 30, 150, 'cm'),
                    onSaved: (v) => _heightCm = v ?? '',
                  ),
                  const SizedBox(height: Spacing.md),

                  // ── 머리둘레 ──────────────────────────────────
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: l10n.growthHeadLabel,
                      hintText: l10n.growthHeadHint,
                      suffixText: 'cm',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => _validateRange(l10n, v, 25, 60, 'cm'),
                    onSaved: (v) => _headCm = v ?? '',
                  ),
                  const SizedBox(height: Spacing.lg),

                  // ── 메모 ───────────────────────────────────────
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: l10n.commonMemoOptional,
                      hintText: l10n.growthMemoHint,
                    ),
                    onChanged: (v) => _note = v,
                    maxLines: 2,
                  ),

                  const SizedBox(height: Spacing.xl),
                  FilledButton.icon(
                    onPressed: isLoading ? null : () => _submit(child.id),
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(isLoading
                        ? l10n.commonSaving
                        : (_isEdit ? l10n.commonSave : l10n.commonRegister)),
                    style: FilledButton.styleFrom(
                      minimumSize:
                          const Size.fromHeight(TouchTarget.huge),
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

  String? _validateRange(AppLocalizations l10n, String? v, double min, double max, String unit) {
    if (v == null || v.isEmpty) return null;
    final n = double.tryParse(v);
    if (n == null) return l10n.commonNumberOnly;
    if (n < min || n > max) return '$min~$max $unit';
    return null;
  }

  String _formatDate(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
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
