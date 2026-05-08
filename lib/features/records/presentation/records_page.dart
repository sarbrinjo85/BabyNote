import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/baby_loading.dart';
import '../../../core/widgets/child_picker_action.dart';
import '../../../core/widgets/stroked_title.dart';
import '../../child/presentation/child_providers.dart';
import '../../child/presentation/selected_child_provider.dart';
import '../../diaper/data/diaper_repository.dart';
import '../../diaper/domain/diaper.dart';
import '../../feeding/data/feeding_repository.dart';
import '../../feeding/domain/feeding.dart';
import '../../inventory/presentation/diaper_inventory_providers.dart';
import '../../inventory/presentation/formula_inventory_providers.dart';
import '../../sleep/data/sleep_repository.dart';
import '../../sleep/domain/sleep.dart';
import '../../stats/presentation/stats_providers.dart';

/// 종합 기록 — 2탭 (일별 통합 / 성장).
///
/// 일별 통합 탭은 수유/수면/기저귀를 시간순으로 묶어 날짜별로 표시.
/// 성장 탭은 측정값 + 가상 아이 크기 시각화.
class RecordsPage extends ConsumerWidget {
  const RecordsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncChildren = ref.watch(myChildrenProvider);

    return Scaffold(
      appBar: AppBar(
        title: StrokedTitle(l10n.recordsTitle, fontSize: 26),
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
            final child = ref.watch(selectedChildProvider) ?? children.first;
            return _DailyTimelineList(childId: child.id);
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 일별 통합 타임라인 — 수유/수면/기저귀 시간순 + 날짜별 그룹
// ─────────────────────────────────────────────────────────────────────────
class _DailyEvent {
  const _DailyEvent({
    required this.when,
    required this.icon,
    required this.title,
    required this.onLongPress,
    this.onTap,
  });
  final DateTime when;
  final String icon;
  final String title;
  final VoidCallback onLongPress;
  final VoidCallback? onTap;
}

class _DailyTimelineList extends ConsumerWidget {
  const _DailyTimelineList({required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final events = <_DailyEvent>[
      ...feedings.map((f) => _DailyEvent(
            when: f.startedAt,
            icon: '🍼',
            title: _summarizeFeeding(l10n, f),
            onTap: () => context.push('/feeding/new', extra: f),
            onLongPress: () => _confirmAndDelete(context, delete: () async {
              await ref.read(feedingRepositoryProvider).deleteFeeding(f.id);
              ref.invalidate(statsFeedingsProvider(childId));
              ref.invalidate(formulaInventoryStatsProvider);
            }),
          )),
      ...sleeps.map((s) => _DailyEvent(
            when: s.startedAt,
            icon: '💤',
            title: _summarizeSleep(l10n, s),
            onTap: s.isOngoing
                ? null
                : () => context.push('/sleep/new', extra: s),
            onLongPress: () => _confirmAndDelete(context, delete: () async {
              await ref.read(sleepRepositoryProvider).deleteSleep(s.id);
              ref.invalidate(statsSleepsProvider(childId));
            }),
          )),
      ...diapers.map((d) => _DailyEvent(
            when: d.recordedAt,
            icon: '💩',
            title: _summarizeDiaper(l10n, d),
            onTap: () => context.push('/diaper/new', extra: d),
            onLongPress: () => _confirmAndDelete(context, delete: () async {
              await ref.read(diaperRepositoryProvider).deleteDiaper(d.id);
              ref.invalidate(statsDiapersProvider(childId));
              ref.invalidate(diaperInventoryStatsProvider);
            }),
          )),
    ];

    if (events.isEmpty) return _EmptyTab(message: l10n.recordsEmpty);

    events.sort((a, b) => b.when.compareTo(a.when));

    final grouped = <String, List<_DailyEvent>>{};
    for (final e in events) {
      final key = _dateKey(e.when);
      grouped.putIfAbsent(key, () => []).add(e);
    }
    final dateKeys = grouped.keys.toList();

    return ListView(
      padding: const EdgeInsets.all(Spacing.md),
      children: [
        for (final key in dateKeys) ...[
          Padding(
            padding: const EdgeInsets.only(top: Spacing.sm, bottom: 4),
            child: Text(
              _formatDateHeader(grouped[key]!.first.when),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          for (final e in grouped[key]!)
            _RecordCard(
              icon: e.icon,
              title: e.title,
              subtitle: _hhmm(e.when),
              onTap: e.onTap,
              onLongPress: e.onLongPress,
            ),
        ],
      ],
    );
  }
}

String _dateKey(DateTime d) =>
    '${d.year}-${_two(d.month)}-${_two(d.day)}';
String _two(int v) => v.toString().padLeft(2, '0');
String _hhmm(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

String _formatDateHeader(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final that = DateTime(d.year, d.month, d.day);
  final diff = today.difference(that).inDays;
  if (diff == 0) return '오늘 (${d.year}.${_two(d.month)}.${_two(d.day)})';
  if (diff == 1) return '어제 (${d.year}.${_two(d.month)}.${_two(d.day)})';
  return '${d.year}.${_two(d.month)}.${_two(d.day)}';
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
// 요약 헬퍼
// ─────────────────────────────────────────────────────────────────────────
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
    return s.napOrNight == 'night'
        ? l10n.sleepNightInProgress
        : l10n.sleepNapInProgress;
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
  if (d.color != null) {
    parts.add(switch (d.color!) {
      'yellow' => l10n.diaperColorYellow,
      'brown' => l10n.diaperColorBrown,
      'green' => l10n.diaperColorGreen,
      'black' => l10n.diaperColorBlack,
      'red' => l10n.diaperColorRed,
      'white' => l10n.diaperColorWhite,
      _ => l10n.diaperColorUnknown,
    });
  }
  if (d.consistency != null) {
    parts.add(switch (d.consistency!) {
      'loose' => l10n.diaperLoose,
      'normal' => l10n.diaperNormal,
      'firm' => l10n.diaperFirm,
      _ => d.consistency!,
    });
  }
  if (d.amount != null) {
    parts.add(switch (d.amount!) {
      'small' => l10n.diaperSmall,
      'normal' => l10n.diaperNormal,
      'large' => l10n.diaperLarge,
      _ => d.amount!,
    });
  }
  return parts.join(' · ');
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
