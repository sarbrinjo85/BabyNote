import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/baby_loading.dart';
import '../../../core/widgets/child_picker_action.dart';
import '../../child/presentation/child_providers.dart';
import '../../child/presentation/selected_child_provider.dart';
import '../../diaper/domain/diaper.dart';
import '../../feeding/domain/feeding.dart';
import '../../sleep/domain/sleep.dart';
import 'stats_providers.dart';

/// 통계 화면 — 1주일/1개월 토글 차트 + 기간 통계 카드.
///
/// (기존 records 페이지에 있던 기간 차트/통계 UI를 이쪽으로 이전)
class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncChildren = ref.watch(myChildrenProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.statsTitle),
        actions: const [ChildPickerAction()],
      ),
      body: SafeArea(
        top: false,
        child: asyncChildren.when(
          loading: () => const Center(child: BabyLoading()),
          error: (err, _) =>
              Center(child: Text(l10n.errorChildrenLoadFailed(err))),
          data: (children) {
            if (children.isEmpty) return _NoChildPlaceholder();
            final selected = ref.watch(selectedChildProvider) ?? children.first;
            return _PeriodView(childId: selected.id);
          },
        ),
      ),
    );
  }
}

enum _PeriodMode { weekly, monthly }

class _PeriodView extends ConsumerStatefulWidget {
  const _PeriodView({required this.childId});
  final String childId;

  @override
  ConsumerState<_PeriodView> createState() => _PeriodViewState();
}

class _PeriodViewState extends ConsumerState<_PeriodView> {
  _PeriodMode _mode = _PeriodMode.weekly;

  @override
  Widget build(BuildContext context) {
    final childId = widget.childId;
    final l10n = AppLocalizations.of(context);
    final asyncFeedings = ref.watch(statsFeedingsProvider(childId));
    final asyncSleeps = ref.watch(statsSleepsProvider(childId));
    final asyncDiapers = ref.watch(statsDiapersProvider(childId));

    if (asyncFeedings.isLoading ||
        asyncSleeps.isLoading ||
        asyncDiapers.isLoading) {
      return const Center(child: BabyLoading());
    }
    if (asyncFeedings.hasError ||
        asyncSleeps.hasError ||
        asyncDiapers.hasError) {
      final err =
          asyncFeedings.error ?? asyncSleeps.error ?? asyncDiapers.error;
      return Center(child: Text(l10n.errorFailed(err!)));
    }

    final feedings = asyncFeedings.value ?? const [];
    final sleeps = asyncSleeps.value ?? const [];
    final diapers = asyncDiapers.value ?? const [];

    // 기간 필터링
    final now = DateTime.now();
    DateTime earliest;
    if (_mode == _PeriodMode.weekly) {
      final today = DateTime(now.year, now.month, now.day);
      earliest = today.subtract(const Duration(days: 6));
    } else {
      earliest = DateTime(now.year, now.month - 11, 1);
    }

    bool inRange(DateTime d) {
      final dd = DateTime(d.year, d.month, d.day);
      return !dd.isBefore(earliest);
    }

    final fInRange = feedings.where((f) => inRange(f.startedAt)).toList();
    final sInRange = sleeps.where((s) => inRange(s.startedAt)).toList();
    final dInRange = diapers.where((d) => inRange(d.recordedAt)).toList();

    return ListView(
      padding: const EdgeInsets.all(Spacing.md),
      children: [
        Center(
          child: SegmentedButton<_PeriodMode>(
            segments: const [
              ButtonSegment(value: _PeriodMode.weekly, label: Text('1주일')),
              ButtonSegment(value: _PeriodMode.monthly, label: Text('1개월')),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
        ),
        const SizedBox(height: Spacing.sm),
        _PeriodTrendChart(
          mode: _mode,
          feedings: fInRange,
          sleeps: sInRange,
          diapers: dInRange,
        ),
        const SizedBox(height: Spacing.sm),
        _PeriodStats(
          mode: _mode,
          feedings: fInRange,
          sleeps: sInRange,
          diapers: dInRange,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 기간 차트
// ─────────────────────────────────────────────────────────────────────────
class _PeriodTrendChart extends StatelessWidget {
  const _PeriodTrendChart({
    required this.mode,
    required this.feedings,
    required this.sleeps,
    required this.diapers,
  });

  final _PeriodMode mode;
  final List<Feeding> feedings;
  final List<Sleep> sleeps;
  final List<Diaper> diapers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    final int n;
    final List<DateTime> buckets;
    if (mode == _PeriodMode.weekly) {
      n = 7;
      final today = DateTime(now.year, now.month, now.day);
      buckets =
          List.generate(n, (i) => today.subtract(Duration(days: n - 1 - i)));
    } else {
      n = 12;
      buckets = List.generate(
          n, (i) => DateTime(now.year, now.month - (n - 1 - i), 1));
    }

    int idxFor(DateTime d) {
      if (mode == _PeriodMode.weekly) {
        final key = DateTime(d.year, d.month, d.day);
        return buckets.indexWhere((k) => k.isAtSameMomentAs(key));
      }
      return buckets.indexWhere((k) => k.year == d.year && k.month == d.month);
    }

    final feedCount = List.filled(n, 0);
    final feedMl = List.filled(n, 0);
    for (final f in feedings) {
      final i = idxFor(f.startedAt);
      if (i >= 0) {
        feedCount[i]++;
        feedMl[i] += f.amountMl ?? 0;
      }
    }

    final sleepMin = List.filled(n, 0);
    for (final s in sleeps) {
      if (s.endedAt == null) continue;
      final i = idxFor(s.startedAt);
      if (i >= 0) {
        sleepMin[i] += s.endedAt!.difference(s.startedAt).inMinutes;
      }
    }

    final diaperCount = List.filled(n, 0);
    for (final d in diapers) {
      final i = idxFor(d.recordedAt);
      if (i >= 0) diaperCount[i]++;
    }

    String bucketLabel(int i) {
      final d = buckets[i];
      if (mode == _PeriodMode.weekly) return '${d.month}/${d.day}';
      return '${d.month}월';
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: Radii.brMd,
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.6),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md, vertical: Spacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mode == _PeriodMode.weekly ? '지난 7일' : '지난 12개월',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: Spacing.xs),
            _MiniBarChart(
              emoji: '🍼',
              label: '수유 횟수',
              values: feedCount.map((v) => v.toDouble()).toList(),
              color: theme.colorScheme.primary,
              valueFormatter: (v) => v == 0 ? '' : '${v.toInt()}',
              dayLabel: bucketLabel,
            ),
            _MiniBarChart(
              emoji: '💤',
              label: '수면 시간',
              values: sleepMin.map((v) => v / 60.0).toList(),
              color: theme.colorScheme.tertiary,
              valueFormatter: (v) => v == 0 ? '' : '${v.toStringAsFixed(1)}h',
              dayLabel: bucketLabel,
            ),
            _MiniBarChart(
              emoji: '💩',
              label: '기저귀',
              values: diaperCount.map((v) => v.toDouble()).toList(),
              color: theme.colorScheme.secondary,
              valueFormatter: (v) => v == 0 ? '' : '${v.toInt()}',
              dayLabel: bucketLabel,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart({
    required this.emoji,
    required this.label,
    required this.values,
    required this.color,
    required this.valueFormatter,
    required this.dayLabel,
  });

  final String emoji;
  final String label;
  final List<double> values;
  final Color color;
  final String Function(double) valueFormatter;
  final String Function(int) dayLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final n = values.length;
    final maxV = values.fold<double>(0, (m, v) => v > m ? v : m);
    final total = values.fold<double>(0, (s, v) => s + v);
    final hasData = total > 0;
    final barWidth = n <= 7 ? 14.0 : (n <= 14 ? 8.0 : 4.0);
    final showValueOnTop = n <= 7;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(label,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
              const Spacer(),
              if (!hasData)
                Text('데이터 없음',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
            ],
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 60,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: maxV == 0 ? 1 : maxV * 1.25,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: showValueOnTop,
                      reservedSize: 14,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= n) return const SizedBox.shrink();
                        return Text(
                          valueFormatter(values[i]),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 16,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= n) return const SizedBox.shrink();
                        final l = dayLabel(i);
                        if (l.isEmpty) return const SizedBox.shrink();
                        return Text(
                          l,
                          style:
                              theme.textTheme.bodySmall?.copyWith(fontSize: 9),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < n; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: values[i],
                          color: color,
                          width: barWidth,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 기간 통계 카드
// ─────────────────────────────────────────────────────────────────────────
class _PeriodStats extends StatelessWidget {
  const _PeriodStats({
    required this.mode,
    required this.feedings,
    required this.sleeps,
    required this.diapers,
  });

  final _PeriodMode mode;
  final List<Feeding> feedings;
  final List<Sleep> sleeps;
  final List<Diaper> diapers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    int feedTotal = feedings.length;
    int feedMlTotal = 0;
    int breastCount = 0, formulaCount = 0, solidCount = 0;
    int breastMl = 0, formulaMl = 0;
    for (final f in feedings) {
      feedMlTotal += f.amountMl ?? 0;
      switch (f.type) {
        case 'breast':
          breastCount++;
          breastMl += f.amountMl ?? 0;
          break;
        case 'formula':
          formulaCount++;
          formulaMl += f.amountMl ?? 0;
          break;
        case 'solid':
          solidCount++;
          break;
      }
    }

    int sleepMin = 0;
    for (final s in sleeps) {
      if (s.endedAt != null) {
        sleepMin += s.endedAt!.difference(s.startedAt).inMinutes;
      }
    }

    int diaperTotal = diapers.length;
    int peeCount = 0, poopCount = 0, bothCount = 0;
    for (final d in diapers) {
      switch (d.type) {
        case 'pee':
          peeCount++;
          break;
        case 'poop':
          poopCount++;
          break;
        case 'both':
          bothCount++;
          break;
      }
    }

    String hm(int min) {
      final h = min ~/ 60;
      final m = min % 60;
      if (h == 0) return '${m}분';
      if (m == 0) return '${h}시간';
      return '${h}시간 ${m}분';
    }

    final periodLabel =
        mode == _PeriodMode.weekly ? '지난 7일' : '지난 12개월';
    final divisor = mode == _PeriodMode.weekly ? 7 : 12;
    final perUnit = mode == _PeriodMode.weekly ? '/일' : '/월';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatsCard(
          icon: '🍼',
          title: '수유 ($periodLabel)',
          headline: feedTotal == 0
              ? '기록 없음'
              : '총 $feedTotal회'
                  '${feedMlTotal > 0 ? ' / ${feedMlTotal}ml' : ''}',
          subItems: [
            if (breastCount > 0)
              '· 모유 $breastCount회'
                  '${breastMl > 0 ? ' (${breastMl}ml)' : ''}',
            if (formulaCount > 0)
              '· 분유 $formulaCount회'
                  '${formulaMl > 0 ? ' (${formulaMl}ml)' : ''}',
            if (solidCount > 0) '· 이유식 $solidCount회',
          ],
          color: theme.colorScheme.primary,
        ),
        _StatsCard(
          icon: '💤',
          title: '수면 ($periodLabel)',
          headline: sleepMin == 0 ? '기록 없음' : '총 ${hm(sleepMin)}',
          subItems: [
            if (sleepMin > 0)
              '· 평균 ${hm((sleepMin / divisor).round())}$perUnit',
          ],
          color: theme.colorScheme.tertiary,
        ),
        _StatsCard(
          icon: '💩',
          title: '기저귀 ($periodLabel)',
          headline: diaperTotal == 0 ? '기록 없음' : '총 $diaperTotal회',
          subItems: [
            if (peeCount > 0) '· 소변 $peeCount회',
            if (poopCount > 0) '· 대변 $poopCount회',
            if (bothCount > 0) '· 둘 다 $bothCount회',
          ],
          color: theme.colorScheme.secondary,
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.icon,
    required this.title,
    required this.headline,
    required this.subItems,
    required this.color,
  });
  final String icon;
  final String title;
  final String headline;
  final List<String> subItems;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: Radii.brMd,
        side: BorderSide(
          color: color.withValues(alpha: 0.6),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md, vertical: Spacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              headline,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            for (final s in subItems)
              Padding(
                padding: const EdgeInsets.only(top: 2, left: 6),
                child: Text(
                  s,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                ),
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
