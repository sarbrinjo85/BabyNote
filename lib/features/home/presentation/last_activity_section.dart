import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// 홈에 표시되는 "마지막 활동" 섹션. 다국어 지원.
class LastActivitySection extends ConsumerWidget {
  const LastActivitySection({super.key, required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncFeedings = ref.watch(recentFeedingsProvider(childId));
    final asyncSleeps = ref.watch(recentSleepsProvider(childId));
    final asyncDiapers = ref.watch(recentDiapersProvider(childId));
    final asyncGrowths = ref.watch(growthsProvider(childId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActivityCard(
          icon: '🍼',
          label: l10n.summaryFeeding,
          value: asyncFeedings.maybeWhen(
            data: (list) => list.isEmpty ? null : _summarizeFeeding(l10n, list.first),
            orElse: () => null,
          ),
          time: asyncFeedings.maybeWhen(
            data: (list) =>
                list.isEmpty ? null : TimeAgo.format(l10n, list.first.startedAt),
            orElse: () => null,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        _ActivityCard(
          icon: '💤',
          label: l10n.summarySleep,
          value: asyncSleeps.maybeWhen(
            data: (list) => list.isEmpty ? null : _summarizeSleep(l10n, list.first),
            orElse: () => null,
          ),
          time: asyncSleeps.maybeWhen(
            data: (list) =>
                list.isEmpty ? null : TimeAgo.format(l10n, list.first.startedAt),
            orElse: () => null,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        _ActivityCard(
          icon: '💩',
          label: l10n.summaryDiaper,
          value: asyncDiapers.maybeWhen(
            data: (list) => list.isEmpty ? null : _summarizeDiaper(l10n, list.first),
            orElse: () => null,
          ),
          time: asyncDiapers.maybeWhen(
            data: (list) =>
                list.isEmpty ? null : TimeAgo.format(l10n, list.first.recordedAt),
            orElse: () => null,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        _ActivityCard(
          icon: '📏',
          label: l10n.summaryGrowth,
          value: asyncGrowths.maybeWhen(
            data: (list) => list.isEmpty ? null : _summarizeGrowth(list.last),
            orElse: () => null,
          ),
          time: asyncGrowths.maybeWhen(
            data: (list) =>
                list.isEmpty ? null : TimeAgo.format(l10n, list.last.measuredAt),
            orElse: () => null,
          ),
        ),
      ],
    );
  }

  String _summarizeFeeding(AppLocalizations l10n, Feeding f) {
    switch (f.type) {
      case 'breast':
        final side = switch (f.breastSide) {
          'left' => l10n.feedingBreastLeft,
          'right' => l10n.feedingBreastRight,
          'both' => l10n.feedingBreastBoth,
          _ => '',
        };
        return '${l10n.feedingTabBreast}${side.isEmpty ? '' : ' ($side)'}'
            '${f.amountMl != null ? ' · ${f.amountMl}ml' : ''}';
      case 'formula':
        final amount = f.amountMl != null ? '${f.amountMl}ml' : '';
        final brand = f.formulaBrand != null && f.formulaBrand!.isNotEmpty
            ? ' · ${f.formulaBrand}'
            : '';
        return '${l10n.feedingTabFormula} $amount$brand';
      case 'solid':
        return '${l10n.feedingTabSolid}: ${f.foodName ?? ''}';
      default:
        return f.type;
    }
  }

  String _summarizeSleep(AppLocalizations l10n, Sleep s) {
    final kind = s.napOrNight == 'night' ? l10n.sleepNight : l10n.sleepNap;
    if (s.isOngoing) {
      return s.napOrNight == 'night' ? l10n.sleepNightInProgress : l10n.sleepNapInProgress;
    }
    final minutes = s.elapsedMinutes(s.endedAt!);
    if (minutes < 60) return '$kind ${l10n.sleepDurationMinutes(minutes)}';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$kind ${h}h' : '$kind ${h}h ${m}m';
  }

  String _summarizeDiaper(AppLocalizations l10n, Diaper d) {
    final type = switch (d.type) {
      'pee' => l10n.diaperPee,
      'poop' => l10n.diaperPoop,
      'both' => l10n.diaperBoth,
      _ => d.type,
    };
    final parts = <String>[type];
    if (d.color != null) parts.add(_colorLabel(l10n, d.color!));
    if (d.consistency != null) parts.add(_consistencyLabel(l10n, d.consistency!));
    if (d.amount != null) parts.add(_amountLabel(l10n, d.amount!));
    return parts.join(' · ');
  }

  String _colorLabel(AppLocalizations l10n, String c) => switch (c) {
        'yellow' => l10n.diaperColorYellow,
        'brown' => l10n.diaperColorBrown,
        'green' => l10n.diaperColorGreen,
        'black' => l10n.diaperColorBlack,
        'red' => l10n.diaperColorRed,
        'white' => l10n.diaperColorWhite,
        _ => l10n.diaperColorUnknown,
      };

  String _consistencyLabel(AppLocalizations l10n, String c) => switch (c) {
        'loose' => l10n.diaperLoose,
        'normal' => l10n.diaperNormal,
        'firm' => l10n.diaperFirm,
        _ => c,
      };

  String _amountLabel(AppLocalizations l10n, String a) => switch (a) {
        'small' => l10n.diaperSmall,
        'normal' => l10n.diaperNormal,
        'large' => l10n.diaperLarge,
        _ => a,
      };

  String _summarizeGrowth(Growth g) {
    final parts = <String>[];
    if (g.weightG != null) parts.add('${(g.weightG! / 1000).toStringAsFixed(2)}kg');
    if (g.heightMm != null) parts.add('${(g.heightMm! / 10).toStringAsFixed(1)}cm');
    if (g.headCircumferenceMm != null) {
      parts.add('${(g.headCircumferenceMm! / 10).toStringAsFixed(1)}cm');
    }
    return parts.join(' / ');
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.time,
  });

  final String icon;
  final String label;
  final String? value;
  final String? time;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final empty = value == null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md, vertical: Spacing.sm),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
                  Text(
                    empty ? l10n.commonNoRecordYet : value!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: empty
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            if (time != null)
              Text(time!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
          ],
        ),
      ),
    );
  }
}
