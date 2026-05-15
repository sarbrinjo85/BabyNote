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
import '../../growth/data/growth_repository.dart';
import '../../growth/domain/growth.dart';
import '../../routine/domain/routine.dart';
import '../../sleep/domain/sleep.dart';
import '../../symptom/domain/symptom.dart';
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.statsTitle),
          actions: const [ChildPickerAction()],
          bottom: const TabBar(
            tabs: [
              Tab(text: '기간 통계'),
              Tab(text: '성장 통계'),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: asyncChildren.when(
            loading: () => const Center(child: BabyLoading()),
            error: (err, _) =>
                Center(child: Text(l10n.errorChildrenLoadFailed(err))),
            data: (children) {
              if (children.isEmpty) return _NoChildPlaceholder();
              final selected =
                  ref.watch(selectedChildProvider) ?? children.first;
              return TabBarView(
                children: [
                  _PeriodView(childId: selected.id),
                  _GrowthList(childId: selected.id),
                ],
              );
            },
          ),
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
    final asyncRoutines = ref.watch(statsRoutinesProvider(childId));
    final asyncSymptoms = ref.watch(statsSymptomsProvider(childId));

    if (asyncFeedings.isLoading ||
        asyncSleeps.isLoading ||
        asyncDiapers.isLoading ||
        asyncRoutines.isLoading ||
        asyncSymptoms.isLoading) {
      return const Center(child: BabyLoading());
    }
    if (asyncFeedings.hasError ||
        asyncSleeps.hasError ||
        asyncDiapers.hasError ||
        asyncRoutines.hasError ||
        asyncSymptoms.hasError) {
      final err = asyncFeedings.error ??
          asyncSleeps.error ??
          asyncDiapers.error ??
          asyncRoutines.error ??
          asyncSymptoms.error;
      return Center(child: Text(l10n.errorFailed(err!)));
    }

    final feedings = asyncFeedings.value ?? const [];
    final sleeps = asyncSleeps.value ?? const [];
    final diapers = asyncDiapers.value ?? const [];
    final routines = asyncRoutines.value ?? const [];
    final symptoms = asyncSymptoms.value ?? const [];

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
    final rInRange = routines.where((r) => inRange(r.startedAt)).toList();
    final symInRange = symptoms.where((s) => inRange(s.occurredAt)).toList();

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
        const SizedBox(height: Spacing.sm),
        _RoutineStatsCard(mode: _mode, routines: rInRange),
        const SizedBox(height: Spacing.sm),
        _SymptomStatsCard(mode: _mode, symptoms: symInRange),
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

// ─────────────────────────────────────────────────────────────────────────
// 루틴 통계 — kind 별 횟수 + 산책/목욕 시간 합계
// ─────────────────────────────────────────────────────────────────────────
class _RoutineStatsCard extends StatelessWidget {
  const _RoutineStatsCard({required this.mode, required this.routines});

  final _PeriodMode mode;
  final List<Routine> routines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final periodLabel =
        mode == _PeriodMode.weekly ? '지난 7일' : '지난 12개월';

    int walk = 0, bath = 0, supp = 0, snack = 0;
    int walkMin = 0, bathMin = 0;
    for (final r in routines) {
      switch (r.kind) {
        case RoutineKind.walk:
          walk++;
          walkMin += r.durationMin ?? 0;
          break;
        case RoutineKind.bath:
          bath++;
          bathMin += r.durationMin ?? 0;
          break;
        case RoutineKind.supplement:
          supp++;
          break;
        case RoutineKind.snack:
          snack++;
          break;
      }
    }
    final total = routines.length;

    String hm(int min) {
      final h = min ~/ 60;
      final m = min % 60;
      if (h == 0) return '$m분';
      if (m == 0) return '$h시간';
      return '$h시간 $m분';
    }

    return _StatsCard(
      icon: '🚶',
      title: '루틴 ($periodLabel)',
      headline: total == 0 ? '기록 없음' : '총 $total회',
      subItems: [
        if (walk > 0)
          '· 산책 $walk회${walkMin > 0 ? ' (${hm(walkMin)})' : ''}',
        if (bath > 0)
          '· 목욕 $bath회${bathMin > 0 ? ' (${hm(bathMin)})' : ''}',
        if (supp > 0) '· 영양제 $supp회',
        if (snack > 0) '· 간식 $snack회',
      ],
      color: theme.colorScheme.primary,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 건강 통계 — kind 별 횟수 + severity 분포
// ─────────────────────────────────────────────────────────────────────────
class _SymptomStatsCard extends StatelessWidget {
  const _SymptomStatsCard({required this.mode, required this.symptoms});

  final _PeriodMode mode;
  final List<Symptom> symptoms;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final periodLabel =
        mode == _PeriodMode.weekly ? '지난 7일' : '지난 12개월';

    int cough = 0, vomit = 0, rash = 0, injury = 0;
    int severeCount = 0;
    for (final s in symptoms) {
      switch (s.kind) {
        case SymptomKind.cough:
          cough++;
          break;
        case SymptomKind.vomit:
          vomit++;
          break;
        case SymptomKind.rash:
          rash++;
          break;
        case SymptomKind.injury:
          injury++;
          break;
      }
      if (s.severity == Severity.severe) severeCount++;
    }
    final total = symptoms.length;

    return _StatsCard(
      icon: '🩹',
      title: '건강 ($periodLabel)',
      headline: total == 0 ? '기록 없음' : '총 $total건',
      subItems: [
        if (cough > 0) '· 기침 $cough건',
        if (vomit > 0) '· 구토 $vomit건',
        if (rash > 0) '· 발진 $rash건',
        if (injury > 0) '· 상처 $injury건',
        if (severeCount > 0) '⚠ "심함" $severeCount건 — 의사 상담 권장',
      ],
      // severe 가 있으면 강한 강조 색, 없으면 secondary
      color: severeCount > 0
          ? theme.colorScheme.error
          : theme.colorScheme.tertiary,
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

// ─────────────────────────────────────────────────────────────────────────
// 성장 탭 — 가상 아이 크기 시각화 + 측정 기록 리스트
// ─────────────────────────────────────────────────────────────────────────
class _GrowthList extends ConsumerWidget {
  const _GrowthList({required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncList = ref.watch(statsGrowthsProvider(childId));
    return asyncList.when(
      loading: () => const Center(child: BabyLoading()),
      error: (err, _) => Center(child: Text(l10n.errorFailed(err))),
      data: (list) {
        if (list.isEmpty) return _EmptyTab(message: l10n.recordsEmpty);
        final reversed = list.reversed.toList();
        return ListView(
          padding: const EdgeInsets.all(Spacing.md),
          children: [
            _GrowthSizeStrip(growths: list),
            const SizedBox(height: Spacing.md),
            for (final g in reversed)
              _GrowthRecordCard(
                growth: g,
                onTap: () => context.push('/growth/new', extra: g),
                onLongPress: () => _confirmAndDeleteGrowth(
                  context,
                  delete: () async {
                    await ref
                        .read(growthRepositoryProvider)
                        .deleteGrowth(g.id);
                    ref.invalidate(statsGrowthsProvider(childId));
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

String _summarizeGrowth(Growth g) {
  final parts = <String>[];
  if (g.weightG != null) {
    parts.add('${(g.weightG! / 1000).toStringAsFixed(2)}kg');
  }
  if (g.heightMm != null) {
    parts.add('${(g.heightMm! / 10).toStringAsFixed(1)}cm');
  }
  if (g.headCircumferenceMm != null) {
    parts.add('${(g.headCircumferenceMm! / 10).toStringAsFixed(1)}cm');
  }
  return parts.join(' / ');
}

String _shortDate(DateTime d) =>
    '${d.year % 100}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

class _GrowthSizeStrip extends StatelessWidget {
  const _GrowthSizeStrip({required this.growths});
  final List<Growth> growths;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = growths.where((g) => g.heightMm != null).toList();
    if (items.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: Radii.brMd,
          side: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.6),
            width: 1.2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Text(
            '키 데이터를 입력하면 성장 시각화가 보여요',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final hMin = items
        .map((g) => g.heightMm!)
        .reduce((a, b) => a < b ? a : b)
        .toDouble();
    final hMax = items
        .map((g) => g.heightMm!)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    double sizeFor(int heightMm) {
      if (hMax == hMin) return 60;
      final t = (heightMm - hMin) / (hMax - hMin);
      return 30 + t * 80;
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
            Text('아이 크기 변화',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(
              '키에 비례한 시각 표현 — 의료 기준 아님',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final g in items)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('👶',
                              style:
                                  TextStyle(fontSize: sizeFor(g.heightMm!))),
                          const SizedBox(height: 2),
                          Text(
                            '${(g.heightMm! / 10).toStringAsFixed(1)}cm',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                          if (g.weightG != null)
                            Text(
                              '${(g.weightG! / 1000).toStringAsFixed(2)}kg',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          Text(
                            _shortDate(g.measuredAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrowthRecordCard extends StatelessWidget {
  const _GrowthRecordCard({
    required this.growth,
    required this.onLongPress,
    this.onTap,
  });

  final Growth growth;
  final VoidCallback onLongPress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: Radii.brMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md, vertical: Spacing.sm),
          child: Row(
            children: [
              const Text('📏', style: TextStyle(fontSize: 24)),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(_summarizeGrowth(growth),
                    style: theme.textTheme.titleSmall),
              ),
              Text(
                _shortDate(growth.measuredAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}

Future<void> _confirmAndDeleteGrowth(
  BuildContext context, {
  required Future<void> Function() delete,
}) async {
  final l10n = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.recordDeleteTitle),
      content: Text(l10n.recordsDeleteBody),
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
    await delete();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(duration: const Duration(seconds: 1), content: Text(l10n.recordDeleted)),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(duration: const Duration(seconds: 1), content: Text(l10n.errorFailed(e))));
  }
}
