import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../child/domain/child.dart';
import '../../vaccination/domain/vaccination.dart';
import '../../vaccination/domain/vaccine_schedule.dart';
import '../../vaccination/presentation/vaccination_providers.dart';

/// 홈 화면용 "다가오는 접종" 카드 — 차별화 ②(병원+예방접종) 마무리.
///
/// ── 표시 조건 ────────────────────────────────────────────────────────
/// 자녀의 미접종 예방접종 중 "권장일이 가장 가까운 1건"을 watch.
/// - 권장일이 -∞ ~ +14일 사이면 카드 표시 (지난 미접종 또는 곧 다가오는)
/// - 그 외(15일 이상 남음 / schedule 없음 / 모두 완료)면 카드 숨김 (SizedBox.shrink)
///
/// ── 매칭 로직 ────────────────────────────────────────────────────────
/// vaccine_list_page와 동일한 `vaccine_code::dose_number` 키로 join.
/// 일관된 동작을 위해 같은 알고리즘 사용.
class UpcomingVaccineCard extends ConsumerWidget {
  const UpcomingVaccineCard({super.key, required this.child});

  /// 어느 자녀의 접종 일정을 보여줄지. 자녀 1명일 때 home_page에서 cs.first 전달.
  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // KR 하드코드 — 추후 user_profiles.country watch로 확장 (vaccine_list_page와 동일).
    final asyncSchedules = ref.watch(vaccineSchedulesProvider('KR'));
    final asyncVaccinations = ref.watch(vaccinationsProvider(child.id));

    // 둘 중 하나라도 로딩/에러면 카드 자체를 안 보여줌 (홈 다른 위젯 방해 X).
    if (asyncSchedules.isLoading || asyncVaccinations.isLoading) {
      return const SizedBox.shrink();
    }
    if (asyncSchedules.hasError || asyncVaccinations.hasError) {
      return const SizedBox.shrink();
    }

    final schedules = asyncSchedules.value ?? const [];
    final vaccinations = asyncVaccinations.value ?? const [];

    final next = _findNextUpcoming(child, schedules, vaccinations);
    if (next == null) return const SizedBox.shrink();

    return _Card(entry: next, childId: child.id);
  }

  /// 미접종 + 권장일이 -∞~+14일 사이인 entry 중 daysFromToday 작은 순 1개 반환.
  /// 없으면 null.
  static _UpcomingEntry? _findNextUpcoming(
    Child child,
    List<VaccineSchedule> schedules,
    List<Vaccination> vaccinations,
  ) {
    final byCode = <String, Vaccination>{};
    for (final v in vaccinations) {
      byCode['${v.vaccineCode}::${v.doseNumber}'] = v;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final birthOnly =
        DateTime(child.birthDate.year, child.birthDate.month, child.birthDate.day);

    final candidates = <_UpcomingEntry>[];
    for (final s in schedules) {
      final v = byCode['${s.code}::${s.doseNumber}'];
      // 이미 완료 → 패스
      if (v?.isCompleted ?? false) continue;

      final recommended = birthOnly.add(Duration(days: s.recommendedAgeDays));
      final diff = recommended.difference(today).inDays;

      // -∞ ~ +14일 범위만 (그 이상 미래는 카드로 띄우기엔 너무 멂)
      if (diff > 14) continue;

      candidates.add(_UpcomingEntry(
        schedule: s,
        recommendedDate: recommended,
        daysFromToday: diff,
      ));
    }

    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => a.daysFromToday.compareTo(b.daysFromToday));
    return candidates.first;
  }
}

class _UpcomingEntry {
  const _UpcomingEntry({
    required this.schedule,
    required this.recommendedDate,
    required this.daysFromToday,
  });
  final VaccineSchedule schedule;
  final DateTime recommendedDate;
  final int daysFromToday;

  bool get isOverdue => daysFromToday < 0;
  bool get isToday => daysFromToday == 0;
}

/// 실제 카드 위젯. 분유 잔량 카드와 같은 패턴(InkWell + 좌측 이모지 + 우측 chevron).
class _Card extends StatelessWidget {
  const _Card({required this.entry, required this.childId});
  final _UpcomingEntry entry;
  final String childId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final urgent = entry.isOverdue || entry.isToday;

    // 상태 텍스트 — 지났음 / 오늘 / N일 후
    final String statusText;
    if (entry.isOverdue) {
      statusText = l10n.upcomingVaccineOverdue(-entry.daysFromToday);
    } else if (entry.isToday) {
      statusText = l10n.upcomingVaccineToday;
    } else {
      statusText = l10n.upcomingVaccineDays(entry.daysFromToday);
    }

    return Card(
      color: urgent
          ? theme.colorScheme.errorContainer
          : theme.colorScheme.tertiaryContainer,
      child: InkWell(
        // 탭 → 예방접종 일정 화면으로 이동.
        // 더 좋은 UX는 바로 /vaccine/record로 가는 거지만 schedule + childId extra 필요해서
        // 일단 목록으로 보냄. 추후 single-step 직링크는 N1.5에서.
        onTap: () => context.push('/vaccine'),
        borderRadius: Radii.brMd,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            children: [
              Text(urgent ? '⚠️' : '💉',
                  style: const TextStyle(fontSize: 32)),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.upcomingVaccineTitle,
                        style: theme.textTheme.labelMedium),
                    Text(
                      entry.schedule.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: urgent
                            ? theme.colorScheme.onErrorContainer
                            : theme.colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
