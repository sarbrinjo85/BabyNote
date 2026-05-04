import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../child/presentation/child_providers.dart';
import '../domain/diaper_inventory.dart';
import 'diaper_inventory_providers.dart';

class DiaperInventoryListPage extends ConsumerWidget {
  const DiaperInventoryListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncChildren = ref.watch(myChildrenProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.diaperInventoryTitle),
        actions: [
          IconButton(
            tooltip: l10n.commonAdd,
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/inventory/diaper/new'),
          ),
        ],
      ),
      body: asyncChildren.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(l10n.errorChildLoadFailed(err))),
        data: (children) {
          if (children.isEmpty) return _NoChildPlaceholder();
          final childId = children.first.id;
          final asyncList = ref.watch(diaperInventoriesProvider(childId));

          return asyncList.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text(l10n.diaperInventoryLoadFailure(err))),
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
      ),
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

  final DiaperInventory inventory;
  final String childId;
  final WidgetRef ref;
  final bool showOpenButton;
  final bool showDepleteButton;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final i = inventory;
    final unit = l10n.diaperInventoryCountUnit;
    final subtitle = StringBuffer('${i.size} · ${i.quantity}$unit');
    if (i.brand != null && i.brand!.isNotEmpty) subtitle.write(' · ${i.brand}');
    if (i.usageKind != null) {
      final kind = switch (i.usageKind!) {
        'day' => l10n.diaperInventoryDay,
        'night' => l10n.diaperInventoryNight,
        'all' => l10n.diaperInventoryAll,
        _ => i.usageKind!,
      };
      subtitle.write(' · $kind');
    }
    if (i.openedAt != null) {
      subtitle.write(' · ${_d(i.openedAt!)}');
    } else if (i.purchasedAt != null) {
      subtitle.write(' · ${_d(i.purchasedAt!)}');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md, vertical: Spacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(i.size),
              subtitle: Text(subtitle.toString()),
              trailing: showOpenButton
                  ? TextButton(
                      onPressed: () => ref
                          .read(diaperInventoryControllerProvider.notifier)
                          .open(childId, i.id),
                      child: Text(l10n.formulaActionOpen),
                    )
                  : showDepleteButton
                      ? TextButton(
                          onPressed: () => ref
                              .read(diaperInventoryControllerProvider.notifier)
                              .deplete(childId, i.id),
                          child: Text(l10n.formulaActionDeplete),
                        )
                      : null,
            ),
            if (i.isActive) _StatsRow(inventory: i),
          ],
        ),
      ),
    );
  }

  String _d(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }
}

class _StatsRow extends ConsumerWidget {
  const _StatsRow({required this.inventory});
  final DiaperInventory inventory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncStats = ref.watch(diaperInventoryStatsProvider(inventory));
    return asyncStats.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: Spacing.xs),
        child: LinearProgressIndicator(minHeight: 6),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
        child:
            Text(l10n.formulaRemainCalcFailed(err), style: Theme.of(context).textTheme.bodySmall),
      ),
      data: (stats) {
        final theme = Theme.of(context);
        final unit = l10n.diaperInventoryCountUnit;
        final remainText =
            '${stats.remainingCount}$unit / ${inventory.quantity}$unit';
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
            const Text('🧷', style: TextStyle(fontSize: 48)),
            const SizedBox(height: Spacing.sm),
            Text(l10n.diaperInventoryNone),
            const SizedBox(height: Spacing.md),
            FilledButton.icon(
              onPressed: () => context.push('/inventory/diaper/new'),
              icon: const Icon(Icons.add),
              label: Text(l10n.diaperInventoryAdd),
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
