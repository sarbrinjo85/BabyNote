import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../inventory/presentation/formula_inventory_providers.dart';

/// 홈 화면용 분유 잔량 카드 — 활성 통이 있을 때만 표시.
///
/// 기획서 §4.1 핵심 차별화 디스플레이: "남은 분유: 약 X일 분량".
/// 알림(P3-1d)과 어필리에이트 링크(Phase 5)는 추후 단계.
class FormulaStatusCard extends ConsumerWidget {
  const FormulaStatusCard({super.key, required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncActive = ref.watch(activeFormulaInventoriesProvider(childId));

    return asyncActive.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        // FIFO: 가장 먼저 개봉한 통의 stats 표시 (보통 1개)
        final active = list.first;
        final asyncStats = ref.watch(formulaInventoryStatsProvider(active));
        return asyncStats.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (stats) {
            final theme = Theme.of(context);
            final daysLeft = stats.expectedDaysLeft;
            final urgent = daysLeft < 3 && stats.confidence == 'normal';

            return Card(
              color: urgent
                  ? theme.colorScheme.errorContainer
                  : theme.colorScheme.primaryContainer,
              child: InkWell(
                onTap: () => context.push('/inventory/formula'),
                borderRadius: Radii.brMd,
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Row(
                    children: [
                      Text(urgent ? '⚠️' : '🍼',
                          style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('분유 잔량',
                                style: theme.textTheme.labelMedium),
                            Text(
                              daysLeft >= 999
                                  ? '데이터 부족'
                                  : urgent
                                      ? '약 ${daysLeft.toStringAsFixed(1)}일 후 소진!'
                                      : '약 ${daysLeft.toStringAsFixed(1)}일 분량 남음',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(active.productName,
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
