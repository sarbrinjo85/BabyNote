import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../child/presentation/child_providers.dart';
import '../domain/formula_inventory.dart';
import 'formula_inventory_providers.dart';

/// 분유 재고 목록 — 사용 중 / 보관 중 / 소진 그룹.
class FormulaInventoryListPage extends ConsumerWidget {
  const FormulaInventoryListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncChildren = ref.watch(myChildrenProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('분유 재고'),
        actions: [
          IconButton(
            tooltip: '추가',
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/inventory/formula/new'),
          ),
        ],
      ),
      body: asyncChildren.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('자녀 로딩 실패: $err')),
        data: (children) {
          if (children.isEmpty) return _NoChildPlaceholder();
          final childId = children.first.id;
          final asyncList = ref.watch(formulaInventoriesProvider(childId));

          return asyncList.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) =>
                Center(child: Text('재고 목록 로딩 실패: $err')),
            data: (list) {
              if (list.isEmpty) return _EmptyPlaceholder();
              final active = list.where((i) => i.isActive).toList();
              final stocked = list.where((i) => i.isStocked).toList();
              final depleted = list.where((i) => i.isDepleted).toList();

              return ListView(
                padding: const EdgeInsets.all(Spacing.md),
                children: [
                  if (active.isNotEmpty) ...[
                    const _Section('사용 중'),
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
                    const _Section('보관 중'),
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
                    const _Section('소진'),
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

  final FormulaInventory inventory;
  final String childId;
  final WidgetRef ref;
  final bool showOpenButton;
  final bool showDepleteButton;

  @override
  Widget build(BuildContext context) {
    final i = inventory;
    final subtitle = StringBuffer('${i.containerGrams}g');
    if (i.brand != null && i.brand!.isNotEmpty) subtitle.write(' · ${i.brand}');
    if (i.openedAt != null) {
      subtitle.write(' · 개봉 ${_d(i.openedAt!)}');
    } else if (i.purchasedAt != null) {
      subtitle.write(' · 구매 ${_d(i.purchasedAt!)}');
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
              title: Text(i.productName),
              subtitle: Text(subtitle.toString()),
              trailing: showOpenButton
                  ? TextButton(
                      onPressed: () =>
                          ref.read(formulaInventoryControllerProvider.notifier)
                              .open(childId, i.id),
                      child: const Text('개봉'),
                    )
                  : showDepleteButton
                      ? TextButton(
                          onPressed: () => ref
                              .read(formulaInventoryControllerProvider.notifier)
                              .deplete(childId, i.id),
                          child: const Text('소진'),
                        )
                      : null,
            ),
            // 사용 중 통: 잔량/소진 예상 표시 (P3-1c)
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

/// 사용 중인 통의 잔량 + 소진 예상일 행. stats provider watch.
class _StatsRow extends ConsumerWidget {
  const _StatsRow({required this.inventory});
  final FormulaInventory inventory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(formulaInventoryStatsProvider(inventory));
    return asyncStats.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: Spacing.xs),
        child: LinearProgressIndicator(minHeight: 6),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
        child: Text('잔량 계산 실패: $err',
            style: Theme.of(context).textTheme.bodySmall),
      ),
      data: (stats) {
        final theme = Theme.of(context);
        final remainText =
            '${stats.remainingG.toStringAsFixed(0)}g / ${inventory.containerGrams}g';
        final daysText = stats.expectedDaysLeft >= 999
            ? '데이터 부족'
            : '약 ${stats.expectedDaysLeft.toStringAsFixed(1)}일 후 소진';
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
            if (low)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '※ 개봉 7일 미만 — 예측 정확도 낮음',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🍼', style: TextStyle(fontSize: 48)),
            const SizedBox(height: Spacing.sm),
            const Text('등록된 분유가 없어요'),
            const SizedBox(height: Spacing.md),
            FilledButton.icon(
              onPressed: () => context.push('/inventory/formula/new'),
              icon: const Icon(Icons.add),
              label: const Text('분유 추가'),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.child_friendly, size: 48),
            const SizedBox(height: Spacing.sm),
            const Text('먼저 자녀를 등록해주세요.'),
          ],
        ),
      ),
    );
  }
}
