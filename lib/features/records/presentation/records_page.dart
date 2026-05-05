import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/time_ago.dart';
import '../../../core/widgets/child_picker_action.dart';
import '../../child/presentation/child_providers.dart';
import '../../child/presentation/selected_child_provider.dart';
import '../../diaper/data/diaper_repository.dart';
import '../../diaper/domain/diaper.dart';
import '../../feeding/data/feeding_repository.dart';
import '../../feeding/domain/feeding.dart';
import '../../growth/data/growth_repository.dart';
import '../../growth/domain/growth.dart';
import '../../inventory/presentation/diaper_inventory_providers.dart';
import '../../inventory/presentation/formula_inventory_providers.dart';
import '../../sleep/data/sleep_repository.dart';
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
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.recordsTitle),
          actions: const [ChildPickerAction()],
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: l10n.summaryFeeding),
              Tab(text: l10n.summarySleep),
              Tab(text: l10n.summaryDiaper),
              Tab(text: l10n.summaryGrowth),
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
                  _FeedingList(childId: child.id),
                  _SleepList(childId: child.id),
                  _DiaperList(childId: child.id),
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
// 수유 탭
// ─────────────────────────────────────────────────────────────────────────
class _FeedingList extends ConsumerWidget {
  const _FeedingList({required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncList = ref.watch(statsFeedingsProvider(childId));
    return asyncList.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text(l10n.errorFailed(err))),
      data: (list) {
        if (list.isEmpty) return _EmptyTab(message: l10n.recordsEmpty);
        return ListView.builder(
          padding: const EdgeInsets.all(Spacing.md),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final f = list[i];
            return _RecordCard(
              icon: '🍼',
              title: _summarizeFeeding(l10n, f),
              subtitle: TimeAgo.format(l10n, f.startedAt),
              onTap: () => context.push('/feeding/new', extra: f),
              onLongPress: () => _confirmAndDelete(
                context,
                delete: () async {
                  await ref
                      .read(feedingRepositoryProvider)
                      .deleteFeeding(f.id);
                  ref.invalidate(statsFeedingsProvider(childId));
                  ref.invalidate(formulaInventoryStatsProvider);
                },
              ),
            );
          },
        );
      },
    );
  }
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

// ─────────────────────────────────────────────────────────────────────────
// 수면 탭
// ─────────────────────────────────────────────────────────────────────────
class _SleepList extends ConsumerWidget {
  const _SleepList({required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncList = ref.watch(statsSleepsProvider(childId));
    return asyncList.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text(l10n.errorFailed(err))),
      data: (list) {
        if (list.isEmpty) return _EmptyTab(message: l10n.recordsEmpty);
        return ListView.builder(
          padding: const EdgeInsets.all(Spacing.md),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final s = list[i];
            return _RecordCard(
              icon: '💤',
              title: _summarizeSleep(l10n, s),
              subtitle: TimeAgo.format(l10n, s.startedAt),
              // 진행 중 수면은 편집 막음 — 종료 후 편집.
              onTap: s.isOngoing
                  ? null
                  : () => context.push('/sleep/new', extra: s),
              onLongPress: () => _confirmAndDelete(
                context,
                delete: () async {
                  await ref
                      .read(sleepRepositoryProvider)
                      .deleteSleep(s.id);
                  ref.invalidate(statsSleepsProvider(childId));
                },
              ),
            );
          },
        );
      },
    );
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

// ─────────────────────────────────────────────────────────────────────────
// 기저귀 탭
// ─────────────────────────────────────────────────────────────────────────
class _DiaperList extends ConsumerWidget {
  const _DiaperList({required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncList = ref.watch(statsDiapersProvider(childId));
    return asyncList.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text(l10n.errorFailed(err))),
      data: (list) {
        if (list.isEmpty) return _EmptyTab(message: l10n.recordsEmpty);
        return ListView.builder(
          padding: const EdgeInsets.all(Spacing.md),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final d = list[i];
            return _RecordCard(
              icon: '💩',
              title: _summarizeDiaper(l10n, d),
              subtitle: TimeAgo.format(l10n, d.recordedAt),
              onTap: () => context.push('/diaper/new', extra: d),
              onLongPress: () => _confirmAndDelete(
                context,
                delete: () async {
                  await ref
                      .read(diaperRepositoryProvider)
                      .deleteDiaper(d.id);
                  ref.invalidate(statsDiapersProvider(childId));
                  ref.invalidate(diaperInventoryStatsProvider);
                },
              ),
            );
          },
        );
      },
    );
  }
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
