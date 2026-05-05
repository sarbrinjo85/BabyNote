import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/child_picker_action.dart';
import '../../child/presentation/child_providers.dart';
import '../../child/presentation/selected_child_provider.dart';
import '../domain/formula_inventory.dart';
import 'formula_inventory_providers.dart';

/// 분유 재고 목록 — 사용 중 / 보관 중 / 소진 그룹.
///
/// embed=true면 Scaffold/AppBar 없이 body만 반환 → InventoryHubPage 안에서
/// TabBarView child로 사용. 단독 진입(`/inventory/formula`)은 embed=false.
class FormulaInventoryListPage extends ConsumerWidget {
  const FormulaInventoryListPage({super.key, this.embed = false});

  final bool embed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncChildren = ref.watch(myChildrenProvider);

    final body = SafeArea(top: false, child: asyncChildren.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(l10n.errorChildLoadFailed(err))),
        data: (children) {
          if (children.isEmpty) return _NoChildPlaceholder();
          final childId =
              (ref.watch(selectedChildProvider) ?? children.first).id;
          final asyncList = ref.watch(formulaInventoriesProvider(childId));

          return asyncList.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) =>
                Center(child: Text(l10n.formulaInventoryLoadFailure(err))),
            data: (list) {
              if (list.isEmpty) return _EmptyPlaceholder();
              final active = list.where((i) => i.isActive).toList();
              final stocked = list.where((i) => i.isStocked).toList();
              final depleted = list.where((i) => i.isDepleted).toList();

              return ListView(
                padding: const EdgeInsets.all(Spacing.md),
                children: [
                  if (active.isNotEmpty) ...[
                    _Section(l10n.formulaSectionInUse),
                    ...active.map((i) => _InventoryTile(
                          inventory: i,
                          childId: childId,
                          ref: ref,
                          showOpenButton: false,
                          showDepleteButton: true,
                        )),
                    const SizedBox(height: Spacing.lg),
                  ],
                  if (stocked.isNotEmpty) ...[
                    _Section(l10n.formulaSectionStored),
                    ...stocked.map((i) => _InventoryTile(
                          inventory: i,
                          childId: childId,
                          ref: ref,
                          showOpenButton: true,
                          showDepleteButton: false,
                        )),
                    const SizedBox(height: Spacing.lg),
                  ],
                  if (depleted.isNotEmpty) ...[
                    _Section(l10n.formulaSectionDepleted),
                    ...depleted.map((i) => _InventoryTile(
                          inventory: i,
                          childId: childId,
                          ref: ref,
                          showOpenButton: false,
                          showDepleteButton: false,
                        )),
                  ],
                ],
              );
            },
          );
        },
      ));

    if (embed) {
      // Hub 내부에서 호출 — Scaffold + 추가 버튼 X (Hub의 AppBar가 처리)
      return body;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.formulaInventoryTitle),
        actions: [
          const ChildPickerAction(),
          IconButton(
            tooltip: l10n.commonAdd,
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/inventory/formula/new'),
          ),
        ],
      ),
      body: body,
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({
    required this.inventory,
    required this.childId,
    required this.ref,
    required this.showOpenButton,
    required this.showDepleteButton,
  });

  final FormulaInventory inventory;
  final String childId;
  final WidgetRef ref;
  final bool showOpenButton;
  final bool showDepleteButton;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final i = inventory;
    final subtitle = StringBuffer('${i.containerGrams}g');
    if (i.brand != null && i.brand!.isNotEmpty) subtitle.write(' · ${i.brand}');
    if (i.openedAt != null) {
      subtitle.write(' · ${_d(i.openedAt!)}');
    } else if (i.purchasedAt != null) {
      subtitle.write(' · ${_d(i.purchasedAt!)}');
    }

    return Card(
      child: InkWell(
        // 단축 탭 → 편집, 길게 누름 → 삭제 confirm
        onTap: () => context.push('/inventory/formula/new', extra: i),
        onLongPress: () => _confirmDelete(context, ref, i),
        borderRadius: Radii.brMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md, vertical: Spacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(i.productName),
                subtitle: Text(subtitle.toString()),
                trailing: showOpenButton
                    ? TextButton(
                        onPressed: () =>
                            ref.read(formulaInventoryControllerProvider.notifier)
                                .open(childId, i.id),
                        child: Text(l10n.formulaActionOpen),
                      )
                    : showDepleteButton
                        ? TextButton(
                            onPressed: () => ref
                                .read(formulaInventoryControllerProvider.notifier)
                                .deplete(childId, i.id),
                            child: Text(l10n.formulaActionDeplete),
                          )
                        : null,
              ),
              // 사용 중 통: 잔량/소진 예상 표시 (P3-1c)
              if (i.isActive) _StatsRow(inventory: i),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, FormulaInventory inv) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.inventoryDeleteTitle),
        content: Text(l10n.inventoryDeleteBody(inv.productName)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.commonCancel)),
          FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.commonDelete)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref
          .read(formulaInventoryControllerProvider.notifier)
          .deleteInventory(childId: childId, id: inv.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.inventoryDeleted)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorFailed(e))));
    }
  }

  String _d(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }
}

/// 사용 중인 통의 잔량 + 소진 예상일 행. stats provider watch.
class _StatsRow extends ConsumerWidget {
  const _StatsRow({required this.inventory});
  final FormulaInventory inventory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncStats = ref.watch(formulaInventoryStatsProvider(inventory));
    return asyncStats.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: Spacing.xs),
        child: LinearProgressIndicator(minHeight: 6),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
        child: Text(l10n.formulaRemainCalcFailed(err),
            style: Theme.of(context).textTheme.bodySmall),
      ),
      data: (stats) {
        final theme = Theme.of(context);
        final remainText =
            '${stats.remainingG.toStringAsFixed(0)}g / ${inventory.containerGrams}g';
        final daysText = stats.expectedDaysLeft >= 999
            ? l10n.commonDataInsufficient
            : l10n.formulaExpectedDays(stats.expectedDaysLeft.toStringAsFixed(1));
        final low = stats.confidence == 'low';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: Radii.brSm,
              child: LinearProgressIndicator(
                value: stats.remainingRatio,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(remainText, style: theme.textTheme.bodySmall),
                Text(
                  daysText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: low
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.xs),
          ],
        );
      },
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🍼', style: TextStyle(fontSize: 48)),
            const SizedBox(height: Spacing.sm),
            Text(l10n.formulaNone),
            const SizedBox(height: Spacing.md),
            FilledButton.icon(
              onPressed: () => context.push('/inventory/formula/new'),
              icon: const Icon(Icons.add),
              label: Text(l10n.formulaAdd),
            ),
          ],
        ),
      ),
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
          ],
        ),
      ),
    );
  }
}
