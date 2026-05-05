import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/time_ago.dart';
import '../../diaper/domain/diaper.dart';
import '../../diaper/presentation/diaper_providers.dart';
import '../../feeding/domain/feeding.dart';
import '../../feeding/presentation/feeding_providers.dart';
import '../../growth/domain/growth.dart';
import '../../growth/presentation/growth_providers.dart';
import '../../inventory/presentation/diaper_inventory_providers.dart';
import '../../inventory/presentation/formula_inventory_providers.dart';
import '../../sleep/domain/sleep.dart';
import '../../sleep/presentation/sleep_providers.dart';

/// 4종 메인 기록 통합 그리드 — 큰 이모지 + 라벨 + 마지막 활동 시간/요약.
///
/// 기존 "오늘의 기록 4-grid" + "마지막 활동 2×2"를 하나로 통합.
/// 각 카드 탭 → register 페이지로 이동.
class RecordButtonsGrid extends ConsumerWidget {
  const RecordButtonsGrid({super.key, required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final asyncFeedings = ref.watch(recentFeedingsProvider(childId));
    final asyncSleeps = ref.watch(recentSleepsProvider(childId));
    final asyncDiapers = ref.watch(recentDiapersProvider(childId));
    final asyncGrowths = ref.watch(growthsProvider(childId));

    final lastFeeding = asyncFeedings.maybeWhen(
      data: (l) => l.isEmpty ? null : l.first,
      orElse: () => null,
    );
    final lastSleep = asyncSleeps.maybeWhen(
      data: (l) => l.isEmpty ? null : l.first,
      orElse: () => null,
    );
    final lastDiaper = asyncDiapers.maybeWhen(
      data: (l) => l.isEmpty ? null : l.first,
      orElse: () => null,
    );
    final lastGrowth = asyncGrowths.maybeWhen(
      data: (l) => l.isEmpty ? null : l.last,
      orElse: () => null,
    );

    // ── 알림 조건 계산 (각 type별) ────────────────────────────────
    // 수유: 활성 분유 통의 expectedDaysLeft < 3 → urgent
    bool feedingAlert = false;
    final asyncActives =
        ref.watch(activeFormulaInventoriesProvider(childId));
    asyncActives.whenData((list) {
      for (final inv in list) {
        final stats = ref.read(formulaInventoryStatsProvider(inv));
        stats.whenData((s) {
          if (s.expectedDaysLeft < 3 && s.expectedDaysLeft >= 0) {
            feedingAlert = true;
          }
        });
      }
    });

    // 수면: 진행 중이면 표시 (alert는 아님 — info)
    final sleepInProgress = lastSleep?.isOngoing ?? false;

    // 기저귀: 사이즈업 14일 이내
    bool diaperAlert = false;
    final asyncForecast =
        ref.watch(diaperSizeUpForecastProvider(childId));
    asyncForecast.whenData((f) {
      if (f != null && f.nextSize != null && f.daysToSizeUp <= 14) {
        diaperAlert = true;
      }
    });

    // 성장: 마지막 측정 + 7일 지남 (또는 측정 0건)
    bool growthAlert = false;
    if (lastGrowth == null) {
      // 자녀 등록 후 7일 이상이면 첫 측정 권유 — 단순히 항상 alert
      growthAlert = true;
    } else {
      final daysSince =
          DateTime.now().difference(lastGrowth.measuredAt).inDays;
      if (daysSince >= 7) growthAlert = true;
    }

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Spacing.xs,
      crossAxisSpacing: Spacing.xs,
      childAspectRatio: 0.78, // 세로로 더 길게 — overflow 방지
      children: [
        _Tile(
          emoji: '🍼',
          label: l10n.summaryFeeding,
          // 수유는 시간 + 양을 한 줄에 합쳐서 표시: "3시간전 120ml"
          summary: lastFeeding == null
              ? null
              : '${TimeAgo.format(l10n, lastFeeding.startedAt)} '
                  '${_summarizeFeeding(l10n, lastFeeding)}',
          time: null,
          alert: feedingAlert,
          onTap: () => context.push('/feeding/new'),
        ),
        _Tile(
          emoji: '💤',
          // 수면 진행 중일 때 라벨을 "수면중"으로 변경
          label: sleepInProgress ? l10n.summarySleeping : l10n.summarySleep,
          summary: lastSleep == null
              ? null
              : '${TimeAgo.format(l10n, lastSleep.startedAt)} '
                  '${_summarizeSleep(l10n, lastSleep)}',
          time: null,
          info: sleepInProgress, // 진행 중 표시 (urgent X, info O)
          onTap: () => context.push('/sleep/new'),
        ),
        _Tile(
          emoji: '💩',
          label: l10n.summaryDiaper,
          summary: lastDiaper == null
              ? null
              : '${TimeAgo.format(l10n, lastDiaper.recordedAt)} '
                  '${_summarizeDiaper(l10n, lastDiaper)}',
          time: null,
          alert: diaperAlert,
          onTap: () => context.push('/diaper/new'),
        ),
        _Tile(
          emoji: '📏',
          label: l10n.summaryGrowth,
          summary: lastGrowth == null
              ? null
              : '${TimeAgo.format(l10n, lastGrowth.measuredAt)} '
                  '${_summarizeGrowth(lastGrowth)}',
          time: null,
          alert: growthAlert,
          onTap: () => context.push('/growth/new'),
        ),
      ],
    );
  }

  String _summarizeFeeding(AppLocalizations l10n, Feeding f) {
    switch (f.type) {
      case 'breast':
        return f.amountMl != null ? '${f.amountMl}ml' : l10n.feedingTabBreast;
      case 'formula':
        return f.amountMl != null ? '${f.amountMl}ml' : l10n.feedingTabFormula;
      case 'solid':
        return l10n.feedingTabSolid;
      default:
        return f.type;
    }
  }

  String _summarizeSleep(AppLocalizations l10n, Sleep s) {
    if (s.isOngoing) {
      return s.napOrNight == 'night'
          ? l10n.sleepNightInProgress
          : l10n.sleepNapInProgress;
    }
    final mins = s.elapsedMinutes(s.endedAt!);
    if (mins < 60) return '${mins}m';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h${m}m';
  }

  String _summarizeDiaper(AppLocalizations l10n, Diaper d) {
    return switch (d.type) {
      'pee' => l10n.diaperPee,
      'poop' => l10n.diaperPoop,
      'both' => l10n.diaperBoth,
      _ => d.type,
    };
  }

  String _summarizeGrowth(Growth g) {
    if (g.weightG != null) {
      return '${(g.weightG! / 1000).toStringAsFixed(2)}kg';
    }
    if (g.heightMm != null) {
      return '${(g.heightMm! / 10).toStringAsFixed(1)}cm';
    }
    return '—';
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.emoji,
    required this.label,
    required this.summary,
    required this.time,
    required this.onTap,
    this.alert = false,
    this.info = false,
  });
  final String emoji;
  final String label;
  final String? summary;
  final String? time;
  final VoidCallback onTap;
  /// 빨간 강조 — 분유 곧 소진, 사이즈업 임박, 성장 주간 알림 등.
  final bool alert;
  /// 정보 강조 (진행 중 등) — 카드 색상 secondary로.
  final bool info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final empty = summary == null;
    return Card(
      margin: EdgeInsets.zero,
      color: alert
          ? theme.colorScheme.errorContainer
          : info
              ? theme.colorScheme.secondaryContainer
              : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.brMd,
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(height: 1),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontSize: 11,
                      color: alert
                          ? theme.colorScheme.onErrorContainer
                          : info
                              ? theme.colorScheme.onSecondaryContainer
                              : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    empty ? '—' : summary!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: alert
                          ? theme.colorScheme.onErrorContainer
                          : empty
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (time != null)
                    Text(
                      time!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 9,
                        color: alert
                            ? theme.colorScheme.onErrorContainer
                                .withValues(alpha: 0.8)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              ),
            ),
            // 우상단 알림 dot — alert 또는 info 시
            if (alert || info)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: alert
                        ? theme.colorScheme.error
                        : theme.colorScheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
