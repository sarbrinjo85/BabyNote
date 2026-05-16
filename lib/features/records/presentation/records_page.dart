import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/sync/write_queue.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/baby_loading.dart';
import '../../../core/widgets/child_picker_action.dart';
import '../../child/presentation/child_providers.dart';
import '../../child/presentation/selected_child_provider.dart';
import '../../diaper/data/diaper_repository.dart';
import '../../diaper/domain/diaper.dart';
import '../../feeding/data/feeding_repository.dart';
import '../../feeding/domain/feeding.dart';
import '../../inventory/presentation/diaper_inventory_providers.dart';
import '../../inventory/presentation/formula_inventory_providers.dart';
import '../../routine/data/routine_repository.dart';
import '../../routine/domain/routine.dart';
import '../../routine/presentation/routine_providers.dart';
import '../../sleep/data/sleep_repository.dart';
import '../../sleep/domain/sleep.dart';
import '../../stats/presentation/stats_providers.dart';
import '../../symptom/data/symptom_repository.dart';
import '../../symptom/domain/symptom.dart';
import '../../symptom/presentation/symptom_providers.dart';

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
        title: Text(l10n.recordsTitle),
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
    this.isPending = false,
  });
  final DateTime when;
  final String icon;
  final String title;
  final VoidCallback onLongPress;
  final VoidCallback? onTap;
  /// 큐에 들어있어 아직 서버에 동기화 안 된 row.
  final bool isPending;
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
    // 루틴/증상 — 모든 kind 혼합 30건. listRecent 가 limit=30 이라 충분.
    final asyncRoutines = ref.watch(recentRoutinesProvider(childId));
    final asyncSymptoms = ref.watch(recentSymptomsProvider(childId));

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

    // 큐잉된 row 의 (table, rowId) 셋. 비행기 모드에서 입력 후 화면에 표시.
    final pendingKeys =
        ref.watch(writeQueuePendingKeysProvider).valueOrNull ?? const {};
    bool isPending(String table, String id) =>
        pendingKeys.contains('$table::$id');

    final events = <_DailyEvent>[
      ...feedings.map((f) => _DailyEvent(
            when: f.startedAt,
            icon: '🍼',
            title: _summarizeFeeding(l10n, f),
            isPending: isPending('feedings', f.id),
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
            isPending: isPending('sleeps', s.id),
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
            isPending: isPending('diapers', d.id),
            onTap: () => context.push('/diaper/new', extra: d),
            onLongPress: () => _confirmAndDelete(context, delete: () async {
              await ref.read(diaperRepositoryProvider).deleteDiaper(d.id);
              ref.invalidate(statsDiapersProvider(childId));
              ref.invalidate(diaperInventoryStatsProvider);
            }),
          )),
      ...routines.map((r) => _DailyEvent(
            when: r.startedAt,
            icon: r.kind.emoji,
            title: _summarizeRoutine(l10n, r),
            isPending: isPending('routines', r.id),
            onTap: () => context.push('/routine/new', extra: r),
            onLongPress: () => _confirmAndDelete(context, delete: () async {
              await ref.read(routineRepositoryProvider).delete(r.id);
              ref.invalidate(recentRoutinesProvider(childId));
            }),
          )),
      ...symptoms.map((s) => _DailyEvent(
            when: s.occurredAt,
            icon: s.kind.emoji,
            title: _summarizeSymptom(l10n, s),
            isPending: isPending('symptoms', s.id),
            onTap: () => context.push('/symptom/new', extra: s),
            onLongPress: () => _confirmAndDelete(context, delete: () async {
              await ref.read(symptomRepositoryProvider).delete(s.id);
              ref.invalidate(recentSymptomsProvider(childId));
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
              isPending: e.isPending,
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
      SnackBar(duration: const Duration(seconds: 1), content: Text(l10n.recordDeleted)),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(duration: const Duration(seconds: 1), content: Text(l10n.errorFailed(e))));
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

String _summarizeRoutine(AppLocalizations l10n, Routine r) {
  final label = switch (r.kind) {
    RoutineKind.walk => l10n.routineKindWalk,
    RoutineKind.bath => l10n.routineKindBath,
    RoutineKind.supplement => l10n.routineKindSupplement,
    RoutineKind.snack => l10n.routineKindSnack,
  };
  if (r.kind.usesDuration && r.durationMin != null) {
    return '$label ${r.durationMin}분';
  }
  if (r.kind.usesItemName && r.itemName != null && r.itemName!.isNotEmpty) {
    return '$label · ${r.itemName}';
  }
  return label;
}

String _summarizeSymptom(AppLocalizations l10n, Symptom s) {
  final label = switch (s.kind) {
    SymptomKind.cough => l10n.symptomKindCough,
    SymptomKind.vomit => l10n.symptomKindVomit,
    SymptomKind.rash => l10n.symptomKindRash,
    SymptomKind.injury => l10n.symptomKindInjury,
  };
  final severity = switch (s.severity) {
    Severity.mild => l10n.symptomSeverityMild,
    Severity.moderate => l10n.symptomSeverityModerate,
    Severity.severe => l10n.symptomSeveritySevere,
    null => '',
  };
  return severity.isEmpty ? label : '$label · $severity';
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
    this.isPending = false,
  });

  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onLongPress;
  final VoidCallback? onTap;
  /// 큐 대기 중 — 옅은 노란 배경 + ⏳ 배지로 시각화.
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      // 큐 대기 row 는 옅은 amber 배경으로 차별화.
      color: isPending
          ? theme.colorScheme.tertiaryContainer.withValues(alpha: 0.4)
          : null,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    if (isPending)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(Icons.cloud_upload_outlined,
                                size: 12,
                                color: theme.colorScheme.tertiary),
                            const SizedBox(width: 3),
                            Text(
                              '동기화 대기 중',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: theme.colorScheme.tertiary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
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
