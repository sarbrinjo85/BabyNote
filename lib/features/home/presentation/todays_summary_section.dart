import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../diaper/presentation/diaper_providers.dart';
import '../../feeding/presentation/feeding_providers.dart';
import '../../sleep/presentation/sleep_providers.dart';

/// "오늘의 요약" 섹션 — 자녀의 오늘(0시~현재) 활동 집계.
///
/// ── 집계 항목 ────────────────────────────────────────────────────────
/// - 🍼 수유: 횟수 + 총 ml (모유 양은 입력 안 했으면 ml 0이지만 횟수에는 포함)
/// - 💤 수면: 총 분(시간:분 표시) — 종료된 수면만 합산. 진행 중은 카운트 X
/// - 💩 기저귀: 횟수 (소변/대변 합쳐서. "둘다"는 1회)
///
/// ── 집계 방법 ────────────────────────────────────────────────────────
/// 별도 server-side aggregation 안 만들고, 이미 있는 recent*Provider(family)
/// 결과(최근 20건)를 클라이언트에서 "오늘 0시 이후"로 필터링 + 집계.
/// 신생아 활동량(수유 6~10회, 기저귀 8~12회)이라 20건이면 충분.
class TodaysSummarySection extends ConsumerWidget {
  const TodaysSummarySection({super.key, required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncFeedings = ref.watch(recentFeedingsProvider(childId));
    final asyncSleeps = ref.watch(recentSleepsProvider(childId));
    final asyncDiapers = ref.watch(recentDiapersProvider(childId));

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    // 수유 집계
    final feedingSummary = asyncFeedings.maybeWhen(
      data: (list) {
        final today =
            list.where((f) => f.startedAt.isAfter(startOfToday)).toList();
        final totalMl = today.fold<int>(
            0, (sum, f) => sum + (f.amountMl ?? 0));
        return _Summary(count: today.length, value: '${today.length}× / $totalMl ml');
      },
      orElse: () => null,
    );

    // 수면 집계 — 종료된 수면만 합산
    final sleepSummary = asyncSleeps.maybeWhen(
      data: (list) {
        final today = list
            .where((s) => s.startedAt.isAfter(startOfToday) && s.endedAt != null)
            .toList();
        final totalMinutes = today.fold<int>(
          0,
          (sum, s) => sum + s.endedAt!.difference(s.startedAt).inMinutes,
        );
        if (totalMinutes == 0) {
          return _Summary(count: today.length, value: l10n.sleepDurationMinutes(0));
        }
        final h = totalMinutes ~/ 60;
        final m = totalMinutes % 60;
        final text = h == 0 ? l10n.sleepDurationMinutes(m) : (m == 0 ? '${h}h' : '${h}h ${m}m');
        return _Summary(count: today.length, value: text);
      },
      orElse: () => null,
    );

    // 기저귀 집계
    final diaperSummary = asyncDiapers.maybeWhen(
      data: (list) {
        final today =
            list.where((d) => d.recordedAt.isAfter(startOfToday)).toList();
        return _Summary(count: today.length, value: '${today.length}×');
      },
      orElse: () => null,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(l10n.summaryTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                const Spacer(),
                Text(
                  '${now.year}-${_two(now.month)}-${_two(now.day)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            _MetricRow(icon: '🍼', label: l10n.summaryFeeding, summary: feedingSummary),
            const SizedBox(height: Spacing.xs),
            _MetricRow(icon: '💤', label: l10n.summarySleep, summary: sleepSummary),
            const SizedBox(height: Spacing.xs),
            _MetricRow(icon: '💩', label: l10n.summaryDiaper, summary: diaperSummary),
          ],
        ),
      ),
    );
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}

class _Summary {
  const _Summary({required this.count, required this.value});
  final int count;
  final String value;
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.label,
    required this.summary,
  });

  final String icon;
  final String label;
  final _Summary? summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final empty = summary == null || summary!.count == 0;
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: Spacing.sm),
        SizedBox(width: 56, child: Text(label, style: theme.textTheme.bodyMedium)),
        Expanded(
          child: Text(
            empty ? l10n.commonNoEntryYet : summary!.value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: empty
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
