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
import '../../sleep/domain/sleep.dart';
import '../../sleep/presentation/sleep_providers.dart';

/// 마지막 활동 2×2 grid — 4종 record의 가장 최근 1건씩.
///
/// 카드 탭 → 해당 register 페이지(편집 화면 X — 새 기록 등록 진입).
/// 데이터 없으면 placeholder로 "—" 표시.
class LastActivityGrid extends ConsumerWidget {
  const LastActivityGrid({super.key, required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final asyncFeedings = ref.watch(recentFeedingsProvider(childId));
    final asyncSleeps = ref.watch(recentSleepsProvider(childId));
    final asyncDiapers = ref.watch(recentDiapersProvider(childId));
    final asyncGrowths = ref.watch(growthsProvider(childId));

    final lastFeeding = asyncFeedings.maybeWhen(
      data: (list) => list.isEmpty ? null : list.first,
      orElse: () => null,
    );
    final lastSleep = asyncSleeps.maybeWhen(
      data: (list) => list.isEmpty ? null : list.first,
      orElse: () => null,
    );
    final lastDiaper = asyncDiapers.maybeWhen(
      data: (list) => list.isEmpty ? null : list.first,
      orElse: () => null,
    );
    final lastGrowth = asyncGrowths.maybeWhen(
      data: (list) => list.isEmpty ? null : list.last,
      orElse: () => null,
    );

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: Spacing.xs,
      crossAxisSpacing: Spacing.xs,
      childAspectRatio: 2.4, // 가로:세로
      children: [
        _Tile(
          emoji: '🍼',
          label: l10n.summaryFeeding,
          value: lastFeeding == null
              ? null
              : _summarizeFeeding(l10n, lastFeeding),
          time: lastFeeding == null
              ? null
              : TimeAgo.format(l10n, lastFeeding.startedAt),
          onTap: () => context.push('/feeding/new'),
        ),
        _Tile(
          emoji: '💤',
          label: l10n.summarySleep,
          value:
              lastSleep == null ? null : _summarizeSleep(l10n, lastSleep),
          time: lastSleep == null
              ? null
              : TimeAgo.format(l10n, lastSleep.startedAt),
          onTap: () => context.push('/sleep/new'),
        ),
        _Tile(
          emoji: '💩',
          label: l10n.summaryDiaper,
          value: lastDiaper == null
              ? null
              : _summarizeDiaper(l10n, lastDiaper),
          time: lastDiaper == null
              ? null
              : TimeAgo.format(l10n, lastDiaper.recordedAt),
          onTap: () => context.push('/diaper/new'),
        ),
        _Tile(
          emoji: '📏',
          label: l10n.summaryGrowth,
          value: lastGrowth == null ? null : _summarizeGrowth(lastGrowth),
          time: lastGrowth == null
              ? null
              : TimeAgo.format(l10n, lastGrowth.measuredAt),
          onTap: () => context.push('/growth/new'),
        ),
      ],
    );
  }

  String _summarizeFeeding(AppLocalizations l10n, Feeding f) {
    switch (f.type) {
      case 'breast':
        return '${l10n.feedingTabBreast}${f.amountMl != null ? ' ${f.amountMl}ml' : ''}';
      case 'formula':
        return '${l10n.feedingTabFormula}${f.amountMl != null ? ' ${f.amountMl}ml' : ''}';
      case 'solid':
        return l10n.feedingTabSolid;
      default:
        return f.type;
    }
  }

  String _summarizeSleep(AppLocalizations l10n, Sleep s) {
    final kind = s.napOrNight == 'night' ? l10n.sleepNight : l10n.sleepNap;
    if (s.isOngoing) return '$kind ⏳';
    final mins = s.elapsedMinutes(s.endedAt!);
    if (mins < 60) return '$kind ${mins}m';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '$kind ${h}h' : '$kind ${h}h${m}m';
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
    required this.value,
    required this.time,
    required this.onTap,
  });
  final String emoji;
  final String label;
  final String? value;
  final String? time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final empty = value == null;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.brMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm, vertical: 6),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: Spacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      empty ? '—' : value!,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: empty
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (time != null)
                      Text(
                        time!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
