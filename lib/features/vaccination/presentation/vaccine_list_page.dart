import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../child/domain/child.dart';
import '../../child/presentation/child_providers.dart';
import '../domain/vaccination.dart';
import '../domain/vaccine_schedule.dart';
import 'vaccination_providers.dart';

/// 자녀의 예방접종 일정 목록 — 권장일 기준으로 마스터 + 자녀 기록 매칭.
///
/// ── 매칭 로직 ────────────────────────────────────────────────────────
/// schedule(국가별 표준) + vaccinations(이 자녀의 완료 기록)을 클라이언트에서 join.
/// schedule 하나당 vaccination 0개 또는 1개 (vaccine_code + dose_number 조합).
///
/// 카드 상태:
///   - 완료: ✅ 접종일 표시
///   - 다가옴(권장일 ±7일 이내): 🔔 D-N
///   - 지났는데 미접종: ⚠️ 권장일 X일 지남
///   - 미래: 📅 권장일
class VaccineListPage extends ConsumerWidget {
  const VaccineListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncChildren = ref.watch(myChildrenProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.vaccineListTitle)),
      body: asyncChildren.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(l10n.errorChildLoadFailed(err))),
        data: (children) {
          if (children.isEmpty) return _NoChildPlaceholder();
          final child = children.first;

          // 일단 KR 하드코드 — user_profiles.country watch는 후속 작업
          final asyncSchedules = ref.watch(vaccineSchedulesProvider('KR'));
          final asyncVaccinations =
              ref.watch(vaccinationsProvider(child.id));

          if (asyncSchedules.isLoading || asyncVaccinations.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (asyncSchedules.hasError) {
            return Center(child: Text(l10n.vaccineScheduleLoadFailure(asyncSchedules.error!)));
          }
          if (asyncVaccinations.hasError) {
            return Center(child: Text(l10n.vaccineRecordsLoadFailure(asyncVaccinations.error!)));
          }

          final schedules = asyncSchedules.value ?? const [];
          final vaccinations = asyncVaccinations.value ?? const [];
          final entries = _buildEntries(child, schedules, vaccinations);

          // 분류: 다가오는 / 완료 / 지난(미접종)
          final upcoming = entries
              .where((e) => !e.isCompleted && !e.isOverdue)
              .toList();
          final overdue =
              entries.where((e) => !e.isCompleted && e.isOverdue).toList();
          final completed = entries.where((e) => e.isCompleted).toList();

          return ListView(
            padding: const EdgeInsets.all(Spacing.md),
            children: [
              _Header(child: child),
              const SizedBox(height: Spacing.md),
              if (overdue.isNotEmpty) ...[
                _Section(l10n.vaccineSectionOverdue, urgent: true),
                ...overdue.map((e) => _VaccineCard(entry: e, childId: child.id)),
                const SizedBox(height: Spacing.lg),
              ],
              if (upcoming.isNotEmpty) ...[
                _Section(l10n.vaccineSectionUpcoming),
                ...upcoming.map((e) => _VaccineCard(entry: e, childId: child.id)),
                const SizedBox(height: Spacing.lg),
              ],
              if (completed.isNotEmpty) ...[
                _Section(l10n.vaccineSectionCompleted),
                ...completed.map((e) => _VaccineCard(entry: e, childId: child.id)),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// schedule + (optional) vaccination 합성.
class _Entry {
  _Entry({
    required this.schedule,
    required this.recommendedDate,
    required this.daysFromToday,
    this.vaccination,
  });

  final VaccineSchedule schedule;
  final DateTime recommendedDate;
  /// 오늘 기준 권장일까지 남은 일수. 음수 = 지난 일수.
  final int daysFromToday;
  final Vaccination? vaccination;

  bool get isCompleted => vaccination?.isCompleted ?? false;
  bool get isOverdue => !isCompleted && daysFromToday < 0;
  bool get isImminent =>
      !isCompleted && daysFromToday >= 0 && daysFromToday <= 7;
}

List<_Entry> _buildEntries(
  Child child,
  List<VaccineSchedule> schedules,
  List<Vaccination> vaccinations,
) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  // (vaccine_code + dose_number) → vaccination map
  final byCode = <String, Vaccination>{};
  for (final v in vaccinations) {
    byCode['${v.vaccineCode}::${v.doseNumber}'] = v;
  }

  return schedules.map((s) {
    final recommended =
        DateTime(child.birthDate.year, child.birthDate.month, child.birthDate.day)
            .add(Duration(days: s.recommendedAgeDays));
    final diff = recommended.difference(today).inDays;
    return _Entry(
      schedule: s,
      recommendedDate: recommended,
      daysFromToday: diff,
      vaccination: byCode['${s.code}::${s.doseNumber}'],
    );
  }).toList();
}

class _Header extends StatelessWidget {
  const _Header({required this.child});
  final Child child;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.child_care),
        const SizedBox(width: Spacing.xs),
        Text(child.name,
            style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, {this.urgent = false});
  final String title;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Row(
        children: [
          if (urgent)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.error, size: 18),
            ),
          Text(title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: urgent
                        ? Theme.of(context).colorScheme.error
                        : null,
                  )),
        ],
      ),
    );
  }
}

class _VaccineCard extends StatelessWidget {
  const _VaccineCard({required this.entry, required this.childId});
  final _Entry entry;
  final String childId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = entry.schedule;
    String two(int v) => v.toString().padLeft(2, '0');
    final dateText =
        '${entry.recommendedDate.year}-${two(entry.recommendedDate.month)}-${two(entry.recommendedDate.day)}';

    String statusText;
    Color? statusColor;
    String emoji;
    if (entry.isCompleted) {
      final administered = entry.vaccination!.administeredAt!;
      statusText =
          '✅ ${administered.year}-${two(administered.month)}-${two(administered.day)} 접종';
      statusColor = theme.colorScheme.primary;
      emoji = '✅';
    } else if (entry.isOverdue) {
      statusText = '⚠️ 권장일 ${(-entry.daysFromToday)}일 지남';
      statusColor = theme.colorScheme.error;
      emoji = '⚠️';
    } else if (entry.isImminent) {
      statusText = '🔔 D-${entry.daysFromToday}';
      statusColor = theme.colorScheme.tertiary;
      emoji = '🔔';
    } else {
      statusText = '📅 ${entry.daysFromToday}일 후';
      statusColor = theme.colorScheme.onSurfaceVariant;
      emoji = '📅';
    }

    return Card(
      child: InkWell(
        borderRadius: Radii.brMd,
        onTap: entry.isCompleted
            ? null
            : () => context.push(
                  '/vaccine/record',
                  extra: {
                    'schedule': entry.schedule,
                    'childId': childId,
                  },
                ),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: theme.textTheme.titleSmall),
                    Text(
                      '${s.code} · ${s.doseNumber}차 · 권장 $dateText',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(statusText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ),
              if (!entry.isCompleted)
                const Icon(Icons.chevron_right),
            ],
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
          ],
        ),
      ),
    );
  }
}
