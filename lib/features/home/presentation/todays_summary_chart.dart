import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../diaper/presentation/diaper_providers.dart';
import '../../feeding/presentation/feeding_providers.dart';
import '../../sleep/presentation/sleep_providers.dart';

/// 오늘의 요약 — 컴팩트 가로 bar chart로 시각화.
///
/// 4개 막대: 수유(횟수), 수면(시간), 기저귀(횟수), 모유/분유 합 ml.
/// 각 항목은 type별 max 기준으로 normalize해서 0~1.0 비율 표시.
class TodaysSummaryChart extends ConsumerWidget {
  const TodaysSummaryChart({super.key, required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final asyncFeedings = ref.watch(recentFeedingsProvider(childId));
    final asyncSleeps = ref.watch(recentSleepsProvider(childId));
    final asyncDiapers = ref.watch(recentDiapersProvider(childId));

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);

    // 오늘 0시 이후 필터링 + 집계
    int feedCount = 0;
    int feedMl = 0;
    asyncFeedings.whenData((list) {
      for (final f in list) {
        if (f.startedAt.isAfter(start)) {
          feedCount++;
          feedMl += f.amountMl ?? 0;
        }
      }
    });

    int sleepMinutes = 0;
    asyncSleeps.whenData((list) {
      for (final s in list) {
        if (s.startedAt.isAfter(start) && s.endedAt != null) {
          sleepMinutes += s.endedAt!.difference(s.startedAt).inMinutes;
        }
      }
    });

    int diaperCount = 0;
    asyncDiapers.whenData((list) {
      for (final d in list) {
        if (d.recordedAt.isAfter(start)) diaperCount++;
      }
    });

    // 막대 4개 — 각 막대가 자기 max에 대한 비율 (0~1) + 라벨 별도 표시
    // 일반 신생아 일평균 reference: 수유 8회, 수면 16시간, 기저귀 10회
    final feedingRatio = (feedCount / 12).clamp(0.0, 1.0);
    final sleepRatio = (sleepMinutes / (16 * 60)).clamp(0.0, 1.0);
    final diaperRatio = (diaperCount / 12).clamp(0.0, 1.0);

    final bars = [
      _BarItem(
        emoji: '🍼',
        label: l10n.summaryFeeding,
        value: '$feedCount${feedMl > 0 ? ' / ${feedMl}ml' : ''}',
        ratio: feedingRatio,
        color: theme.colorScheme.primary,
      ),
      _BarItem(
        emoji: '💤',
        label: l10n.summarySleep,
        value: _formatDuration(sleepMinutes),
        ratio: sleepRatio,
        color: theme.colorScheme.tertiary,
      ),
      _BarItem(
        emoji: '💩',
        label: l10n.summaryDiaper,
        value: '$diaperCount',
        ratio: diaperRatio,
        color: theme.colorScheme.secondary,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md, vertical: Spacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(l10n.summaryTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
                const Spacer(),
                Text(
                  '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.xs),
            // 가로 bar 3개 — 컴팩트
            for (final b in bars) ...[
              Row(
                children: [
                  Text(b.emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 44,
                    child: Text(b.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                        )),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: b.ratio,
                        minHeight: 8,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(b.color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 70,
                    child: Text(
                      b.value,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes == 0) return '0';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}

class _BarItem {
  const _BarItem({
    required this.emoji,
    required this.label,
    required this.value,
    required this.ratio,
    required this.color,
  });
  final String emoji;
  final String label;
  final String value;
  final double ratio;
  final Color color;
}

