import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/time_ago.dart';
import '../../../core/widgets/child_picker_action.dart';
import '../../child/presentation/child_providers.dart';
import '../../child/presentation/selected_child_provider.dart';
import '../../diaper/domain/diaper.dart';
import '../../feeding/domain/feeding.dart';
import '../../growth/data/growth_repository.dart';
import '../../growth/domain/growth.dart';
import '../../sleep/domain/sleep.dart';
import '../../stats/presentation/stats_providers.dart';

/// 전체 기록 페이지 — 4탭(수유/수면/기저귀/성장).
///
/// ── 데이터 ────────────────────────────────────────────────────────────
/// stats_providers의 200건 fetch를 그대로 재사용 (한 곳에서 관리되는 단일 소스).
/// 무한 스크롤은 Phase 후반 — 신생아 활동량 200건이면 7~14일치라 일단 충분.
///
/// ── 삭제 ──────────────────────────────────────────────────────────────
/// 카드 long-press → confirm dialog → 삭제. last_activity_section과 같은 패턴.
class RecordsPage extends ConsumerWidget {
  const RecordsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncChildren = ref.watch(myChildrenProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.recordsTitle),
          actions: const [ChildPickerAction()],
          bottom: const TabBar(
            tabs: [
              Tab(text: '일별 기록'),
              Tab(text: '성장'),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: asyncChildren.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) =>
                Center(child: Text(l10n.errorChildrenLoadFailed(err))),
            data: (children) {
              if (children.isEmpty) {
                return _NoChildPlaceholder();
              }
              final child = ref.watch(selectedChildProvider) ?? children.first;
              return TabBarView(
                children: [
                  _DailyTimelineList(childId: child.id),
                  _GrowthList(childId: child.id),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 일별 통합 타임라인 — 차트 + 기간 통계 (1주일/1개월 토글)
// ─────────────────────────────────────────────────────────────────────────
class _DailyTimelineList extends ConsumerStatefulWidget {
  const _DailyTimelineList({required this.childId});
  final String childId;

  @override
  ConsumerState<_DailyTimelineList> createState() =>
      _DailyTimelineListState();
}

class _DailyTimelineListState extends ConsumerState<_DailyTimelineList> {
  int _periodDays = 7; // 7 또는 30

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
      return const Center(child: CircularProgressIndicator());
    }
    if (asyncFeedings.hasError ||
        asyncSleeps.hasError ||
        asyncDiapers.hasError) {
      final err = asyncFeedings.error ??
          asyncSleeps.error ??
          asyncDiapers.error;
      return Center(child: Text(l10n.errorFailed(err!)));
    }

    final feedings = asyncFeedings.value ?? const [];
    final sleeps = asyncSleeps.value ?? const [];
    final diapers = asyncDiapers.value ?? const [];

    // ── 기간 필터링 (지난 N일 — N=_periodDays) ──────────────────────
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final earliest = today.subtract(Duration(days: _periodDays - 1));

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
        // ── 기간 토글 ────────────────────────────────────────────
        Center(
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 7, label: Text('1주일')),
              ButtonSegment(value: 30, label: Text('1개월')),
            ],
            selected: {_periodDays},
            onSelectionChanged: (s) =>
                setState(() => _periodDays = s.first),
          ),
        ),
        const SizedBox(height: Spacing.sm),

        // ── 차트 (N일 기간) ────────────────────────────────────
        _PeriodTrendChart(
          days: _periodDays,
          feedings: fInRange,
          sleeps: sInRange,
          diapers: dInRange,
        ),
        const SizedBox(height: Spacing.sm),

        // ── 기간 통계 요약 ─────────────────────────────────────
        _PeriodStats(
          l10n: l10n,
          days: _periodDays,
          feedings: fInRange,
          sleeps: sInRange,
          diapers: dInRange,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 공통 삭제 confirm + SnackBar 헬퍼
// ─────────────────────────────────────────────────────────────────────────
Future<void> _confirmAndDelete(
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
      SnackBar(content: Text(l10n.recordDeleted)),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.errorFailed(e))));
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 성장 탭
// ─────────────────────────────────────────────────────────────────────────
class _GrowthList extends ConsumerWidget {
  const _GrowthList({required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncList = ref.watch(statsGrowthsProvider(childId));
    return asyncList.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text(l10n.errorFailed(err))),
      data: (list) {
        if (list.isEmpty) return _EmptyTab(message: l10n.recordsEmpty);
        // 최신순으로 보여주기 — listAll은 asc라 reversed.
        final reversed = list.reversed.toList();
        return ListView.builder(
          padding: const EdgeInsets.all(Spacing.md),
          itemCount: reversed.length,
          itemBuilder: (context, i) {
            final g = reversed[i];
            return _RecordCard(
              icon: '📏',
              title: _summarizeGrowth(g),
              subtitle: TimeAgo.format(l10n, g.measuredAt),
              onTap: () => context.push('/growth/new', extra: g),
              onLongPress: () => _confirmAndDelete(
                context,
                delete: () async {
                  await ref
                      .read(growthRepositoryProvider)
                      .deleteGrowth(g.id);
                  ref.invalidate(statsGrowthsProvider(childId));
                },
              ),
            );
          },
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

// ─────────────────────────────────────────────────────────────────────────
// 공통 카드 + empty placeholder
// ─────────────────────────────────────────────────────────────────────────
class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onLongPress,
    this.onTap,
  });

  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onLongPress;
  /// 단축 탭 — 편집 화면으로 이동. null이면 편집 불가 (진행 중 수면 등).
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
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(title, style: theme.textTheme.titleSmall),
              ),
              Text(
                subtitle,
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
// 1주일 추세 미니 차트 — 수유/수면/기저귀 각 metric의 일자별 합계
// ─────────────────────────────────────────────────────────────────────────
class _PeriodTrendChart extends StatelessWidget {
  const _PeriodTrendChart({
    required this.days,
    required this.feedings,
    required this.sleeps,
    required this.diapers,
  });

  final int days; // 7 or 30
  final List<Feeding> feedings;
  final List<Sleep> sleeps;
  final List<Diaper> diapers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayList = List.generate(
        days, (i) => today.subtract(Duration(days: days - 1 - i)));

    int idxFor(DateTime d) {
      final key = DateTime(d.year, d.month, d.day);
      return dayList.indexWhere((k) => k.isAtSameMomentAs(key));
    }

    final feedCount = List.filled(days, 0);
    final feedMl = List.filled(days, 0);
    for (final f in feedings) {
      final i = idxFor(f.startedAt);
      if (i >= 0) {
        feedCount[i]++;
        feedMl[i] += f.amountMl ?? 0;
      }
    }

    final sleepMin = List.filled(days, 0);
    for (final s in sleeps) {
      if (s.endedAt == null) continue;
      final i = idxFor(s.startedAt);
      if (i >= 0) {
        sleepMin[i] += s.endedAt!.difference(s.startedAt).inMinutes;
      }
    }

    final diaperCount = List.filled(days, 0);
    for (final d in diapers) {
      final i = idxFor(d.recordedAt);
      if (i >= 0) diaperCount[i]++;
    }

    // 1개월일 때는 너무 많아 5일 간격으로만 라벨 표시
    String dayLabel(int i) {
      if (days > 7 && i != 0 && i != days - 1 && i % 5 != 0) return '';
      final d = dayList[i];
      return '${d.month}/${d.day}';
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
            Text(days == 7 ? '지난 7일' : '지난 30일',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: Spacing.xs),
            _MiniBarChart(
              emoji: '🍼',
              label: '수유 횟수',
              values: feedCount.map((v) => v.toDouble()).toList(),
              color: theme.colorScheme.primary,
              valueFormatter: (v) => v == 0 ? '' : '${v.toInt()}',
              dayLabel: dayLabel,
            ),
            _MiniBarChart(
              emoji: '💤',
              label: '수면 시간',
              values: sleepMin.map((v) => v / 60.0).toList(),
              color: theme.colorScheme.tertiary,
              valueFormatter: (v) =>
                  v == 0 ? '' : '${v.toStringAsFixed(1)}h',
              dayLabel: dayLabel,
            ),
            _MiniBarChart(
              emoji: '💩',
              label: '기저귀',
              values: diaperCount.map((v) => v.toDouble()).toList(),
              color: theme.colorScheme.secondary,
              valueFormatter: (v) => v == 0 ? '' : '${v.toInt()}',
              dayLabel: dayLabel,
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
  final List<double> values; // 길이 7
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
    // 일수가 많아지면 막대 폭/값 라벨 줄임
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
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontSize: 9),
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
// 기간 통계 요약 — 수유/수면/기저귀 N일치 합계 + 세분화
// ─────────────────────────────────────────────────────────────────────────
class _PeriodStats extends StatelessWidget {
  const _PeriodStats({
    required this.l10n,
    required this.days,
    required this.feedings,
    required this.sleeps,
    required this.diapers,
  });

  final AppLocalizations l10n;
  final int days;
  final List<Feeding> feedings;
  final List<Sleep> sleeps;
  final List<Diaper> diapers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ── 수유 통계 ──────────────────────────────────────────────
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

    // ── 수면 통계 ──────────────────────────────────────────────
    int sleepMin = 0;
    for (final s in sleeps) {
      if (s.endedAt != null) {
        sleepMin += s.endedAt!.difference(s.startedAt).inMinutes;
      }
    }

    // ── 기저귀 통계 ────────────────────────────────────────────
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

    final periodLabel = days == 7 ? '지난 7일' : '지난 30일';

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
              '· 평균 ${hm((sleepMin / days).round())}/일',
          ],
          color: theme.colorScheme.tertiary,
        ),
        _StatsCard(
          icon: '💩',
          title: '기저귀 ($periodLabel)',
          headline:
              diaperTotal == 0 ? '기록 없음' : '총 $diaperTotal회',
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
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
