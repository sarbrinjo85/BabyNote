import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../child/presentation/child_providers.dart';
import '../../child/presentation/selected_child_provider.dart';
import 'diaper_inventory_providers.dart';

class DiaperInventoryRegisterPage extends ConsumerStatefulWidget {
  const DiaperInventoryRegisterPage({super.key});

  @override
  ConsumerState<DiaperInventoryRegisterPage> createState() =>
      _DiaperInventoryRegisterPageState();
}

class _DiaperInventoryRegisterPageState
    extends ConsumerState<DiaperInventoryRegisterPage> {
  final _formKey = GlobalKey<FormState>();

  String _size = 'M';
  String _brand = '';
  String _quantity = '';
  String? _usageKind;
  String _priceWon = '';
  String _store = '';
  DateTime? _purchasedAt;
  DateTime? _openedAt;

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

    final qty = int.tryParse(_quantity)!;
    final price = int.tryParse(_priceWon);

    await ref.read(diaperInventoryControllerProvider.notifier).create(
          childId: childId,
          size: _size,
          quantity: qty,
          brand: _brand.trim().isEmpty ? null : _brand.trim(),
          usageKind: _usageKind,
          purchasedAt: _purchasedAt,
          priceMinor: price,
          store: _store.trim().isEmpty ? null : _store.trim(),
          openedAt: _openedAt,
        );

    if (!mounted) return;
    final state = ref.read(diaperInventoryControllerProvider);
    state.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.diaperInventorySavedToast)),
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
    final asyncCtrl = ref.watch(diaperInventoryControllerProvider);
    final isLoading = asyncCtrl.isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.diaperInventoryRegister)),
      body: asyncChildren.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(l10n.errorChildrenLoadFailed(err))),
        data: (children) {
          if (children.isEmpty) return _NoChildPlaceholder();
          final child = ref.watch(selectedChildProvider) ?? children.first;

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

                  Text(l10n.diaperInventorySize, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: Spacing.xs),
                  Wrap(
                    spacing: Spacing.xs,
                    children: ['NB', 'S', 'M', 'L', 'XL', 'XXL']
                        .map((s) => ChoiceChip(
                              label: Text(s),
                              selected: _size == s,
                              onSelected: (sel) {
                                if (sel) setState(() => _size = s);
                              },
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: Spacing.lg),

                  TextFormField(
                    decoration: InputDecoration(
                      labelText: l10n.diaperInventoryCount,
                      hintText: l10n.diaperInventoryCountHint,
                      suffixText: l10n.diaperInventoryCountUnit,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return l10n.diaperInventoryCountRequired;
                      final n = int.tryParse(v);
                      if (n == null || n <= 0) return l10n.commonPositiveOnly;
                      if (n > 1000) return l10n.diaperInventoryCountTooMany;
                      return null;
                    },
                    onSaved: (v) => _quantity = v ?? '',
                  ),
                  const SizedBox(height: Spacing.lg),

                  TextFormField(
                    decoration: InputDecoration(
                      labelText: l10n.formulaBrandLabel,
                      hintText: l10n.diaperInventoryBrandHint,
                    ),
                    onSaved: (v) => _brand = v ?? '',
                  ),
                  const SizedBox(height: Spacing.lg),

                  Text(l10n.diaperInventoryUseType,
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: Spacing.xs),
                  SegmentedButton<String>(
                    emptySelectionAllowed: true,
                    segments: [
                      ButtonSegment(value: 'day', label: Text(l10n.diaperInventoryDay)),
                      ButtonSegment(value: 'night', label: Text(l10n.diaperInventoryNight)),
                      ButtonSegment(value: 'all', label: Text(l10n.diaperInventoryAll)),
                    ],
                    selected: _usageKind == null ? {} : {_usageKind!},
                    onSelectionChanged: (s) =>
                        setState(() => _usageKind = s.isEmpty ? null : s.first),
                  ),
                  const SizedBox(height: Spacing.lg),

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
                    decoration: InputDecoration(
                      labelText: l10n.formulaPriceLabel,
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
                    decoration: InputDecoration(
                      labelText: l10n.formulaShopLabel,
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
                    label: Text(isLoading ? l10n.commonSaving : l10n.commonRegister),
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
