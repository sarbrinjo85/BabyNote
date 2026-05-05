import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../child/presentation/child_providers.dart';
import '../../growth/domain/growth.dart';
import 'stats_providers.dart';

/// 통계 화면.
///
/// ── 차트 4종 ─────────────────────────────────────────────────────────
/// 1. 일별 수유 횟수 (지난 7일, 막대)
/// 2. 일별 수면 총 분 (지난 7일, 막대)
/// 3. 일별 기저귀 횟수 (지난 7일, 막대)
/// 4. 성장 곡선 (체중 시계열, 라인) — 모든 기록
///
/// 신생아 활동량 기준으로 7일치 = 약 70~140건이라 statsXProvider(200건)로 충분.
class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncChildren = ref.watch(myChildrenProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statsTitle)),
      body: asyncChildren.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) =>
            Center(child: Text(l10n.errorChildrenLoadFailed(err))),
        data: (children) {
          if (children.isEmpty) {
            return _NoChildPlaceholder();
          }
          // Phase 단순화: 첫 자녀. 자녀 picker는 후속.
          final childId = children.first.id;

          return ListView(
            padding: const EdgeInsets.all(Spacing.md),
            children: [
              _ChartCard(
                title: l10n.statsFeedingDaily,
                subtitle: l10n.statsLast7Days,
                child: _FeedingBarChart(childId: childId),
              ),
              const SizedBox(height: Spacing.md),
              _ChartCard(
                title: l10n.statsSleepDaily,
                subtitle: l10n.statsLast7DaysHours,
                child: _SleepBarChart(childId: childId),
              ),
              const SizedBox(height: Spacing.md),
              _ChartCard(
                title: l10n.statsDiaperDaily,
                subtitle: l10n.statsLast7Days,
                child: _DiaperBarChart(childId: childId),
              ),
              const SizedBox(height: Spacing.md),
              _ChartCard(
                title: l10n.statsGrowthCurve,
                subtitle: l10n.statsAllRecords,
                child: _GrowthLineChart(childId: childId),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 차트 1개를 감싸는 카드 + 제목/부제 + 고정 높이 영역.
class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
            Text(subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
            const SizedBox(height: Spacing.md),
            SizedBox(height: 200, child: child),
          ],
        ),
      ),
    );
  }
}

/// 지난 7일 일별 카운트 데이터 한 묶음 — 막대 차트 input.
class _DailyCounts {
  _DailyCounts(this.values, this.labels);
  final List<double> values;
  final List<String> labels; // X축 레이블 (요일 또는 일자)
}

_DailyCounts _bucketByDay<T>(
  List<T> items,
  DateTime Function(T) timestamp, {
  int days = 7,
  double Function(T)? weight,
}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final values = List<double>.filled(days, 0);
  final labels = List<String>.filled(days, '');

  for (var i = 0; i < days; i++) {
    final day = today.subtract(Duration(days: days - 1 - i));
    labels[i] = '${day.month}/${day.day}';
  }

  for (final item in items) {
    final t = timestamp(item);
    final tDay = DateTime(t.year, t.month, t.day);
    final diff = today.difference(tDay).inDays;
    if (diff < 0 || diff >= days) continue;
    final idx = days - 1 - diff;
    values[idx] += (weight?.call(item) ?? 1.0);
  }

  return _DailyCounts(values, labels);
}

class _FeedingBarChart extends ConsumerWidget {
  const _FeedingBarChart({required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(statsFeedingsProvider(childId));
    return asyncList.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('$err')),
      data: (list) {
        final data = _bucketByDay(list, (f) => f.startedAt);
        return _BarChart(
          values: data.values,
          labels: data.labels,
          color: Theme.of(context).colorScheme.primary,
        );
      },
    );
  }
}

class _SleepBarChart extends ConsumerWidget {
  const _SleepBarChart({required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(statsSleepsProvider(childId));
    return asyncList.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('$err')),
      data: (list) {
        // 분 단위 → 시간 단위로 변환해서 표시 (값이 너무 크지 않게)
        final data = _bucketByDay<dynamic>(
          list,
          (s) => s.startedAt as DateTime,
          weight: (s) {
            final endedAt = s.endedAt as DateTime?;
            if (endedAt == null) return 0;
            return endedAt
                    .difference(s.startedAt as DateTime)
                    .inMinutes /
                60.0;
          },
        );
        return _BarChart(
          values: data.values,
          labels: data.labels,
          color: Theme.of(context).colorScheme.tertiary,
        );
      },
    );
  }
}

class _DiaperBarChart extends ConsumerWidget {
  const _DiaperBarChart({required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(statsDiapersProvider(childId));
    return asyncList.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('$err')),
      data: (list) {
        final data = _bucketByDay(list, (d) => d.recordedAt);
        return _BarChart(
          values: data.values,
          labels: data.labels,
          color: Theme.of(context).colorScheme.secondary,
        );
      },
    );
  }
}

/// 공통 막대 차트 위젯 — fl_chart BarChart 래퍼.
class _BarChart extends StatelessWidget {
  const _BarChart({
    required this.values,
    required this.labels,
    required this.color,
  });

  final List<double> values;
  final List<String> labels;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxV = values.isEmpty
        ? 1.0
        : values.reduce((a, b) => a > b ? a : b);
    final yMax = maxV <= 0 ? 1.0 : (maxV * 1.2);
    final theme = Theme.of(context);

    return BarChart(
      BarChartData(
        maxY: yMax,
        minY: 0,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(enabled: true),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: theme.colorScheme.surfaceContainerHighest,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(0),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    labels[i],
                    style: theme.textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < values.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i],
                  color: color,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _GrowthLineChart extends ConsumerWidget {
  const _GrowthLineChart({required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncList = ref.watch(statsGrowthsProvider(childId));
    return asyncList.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('$err')),
      data: (list) {
        final withWeight = list
            .where((g) => g.weightG != null)
            .toList()
          ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

        if (withWeight.length < 2) {
          return Center(child: Text(l10n.statsNotEnoughData));
        }

        final theme = Theme.of(context);
        final first = withWeight.first.measuredAt;
        // X축: 첫 측정일로부터 며칠.
        final spots = withWeight.map((g) {
          final daysFromFirst =
              g.measuredAt.difference(first).inDays.toDouble();
          final kg = (g.weightG! / 1000.0);
          return FlSpot(daysFromFirst, kg);
        }).toList();

        final maxX = spots.last.x;
        final minY = (withWeight.map((g) => g.weightG! / 1000.0).reduce(
                (a, b) => a < b ? a : b) -
            1)
            .clamp(0, 100)
            .toDouble();
        final maxY = withWeight.map((g) => g.weightG! / 1000.0).reduce(
                (a, b) => a > b ? a : b) +
            1;

        return LineChart(
          LineChartData(
            minX: 0,
            maxX: maxX,
            minY: minY,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: theme.colorScheme.surfaceContainerHighest,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (v, _) => Text(
                    '${v.toStringAsFixed(0)}kg',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (v, _) {
                    final d = first.add(Duration(days: v.toInt()));
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${d.month}/${d.day}',
                        style: theme.textTheme.bodySmall,
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: theme.colorScheme.primary,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color:
                      theme.colorScheme.primary.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
        );
      },
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
              onPressed: () => context.push('/child/new'),
              icon: const Icon(Icons.add),
              label: Text(l10n.commonGoRegisterChild),
            ),
          ],
        ),
      ),
    );
  }
}

// 사용하지 않는 import 경고 회피 — Growth 타입 노출 보장.
// ignore: unused_element
typedef _GrowthAlias = Growth;
