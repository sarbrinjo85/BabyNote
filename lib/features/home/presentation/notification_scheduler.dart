import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/notifications/notification_service.dart';
import '../../child/domain/child.dart';
import '../../growth/presentation/growth_providers.dart';
import '../../inventory/presentation/formula_inventory_providers.dart';
import '../../vaccination/domain/vaccination.dart';
import '../../vaccination/domain/vaccine_schedule.dart';
import '../../vaccination/presentation/vaccination_providers.dart';

/// 자녀 데이터 변경 시 알림을 자동으로 (재)스케줄하는 무음 위젯.
///
/// ── 왜 위젯으로 ──────────────────────────────────────────────────────
/// 별도 백그라운드 service 없이 build cycle에서 ref.watch만으로 자동 동기화.
/// 자녀 변경/분유 잔량 갱신/접종 기록 갱신마다 자동 재실행 → 항상 최신.
///
/// 같은 ID 알림은 OS가 자동 교체 → 중복 알림 X.
///
/// ── 알림 종류 ────────────────────────────────────────────────────────
/// 1. 분유 잔량 1일 전 알림 — 활성 분유 통의 expectedDaysLeft 시점에서 -1일
/// 2. 다가오는 접종 1일 전 알림 — 권장일 -1일
class NotificationScheduler extends ConsumerWidget {
  const NotificationScheduler({super.key, required this.child});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // build cycle에서 schedule 트리거. 무음 (UI X).
    final l10n = AppLocalizations.of(context);

    // 분유 알림
    _scheduleFormulaNotifications(ref, l10n);
    // 접종 알림
    _scheduleVaccineNotifications(ref, l10n);
    // 성장 주간 알림
    _scheduleGrowthWeeklyReminder(ref, l10n);

    return const SizedBox.shrink();
  }

  /// 성장 측정 주간 알림 — 마지막 측정일 + 7일 시점에 알림.
  ///
  /// 측정 0건이면 자녀 등록일 + 7일에 첫 측정 권유.
  void _scheduleGrowthWeeklyReminder(WidgetRef ref, AppLocalizations l10n) {
    final asyncGrowths = ref.watch(growthsProvider(child.id));
    asyncGrowths.whenData((list) {
      final notifId = (child.id.hashCode ^ 0x47526F77) & 0x7fffffff; // 'GRow'

      DateTime baseDate;
      if (list.isEmpty) {
        // 측정 0건 — 자녀 등록일(=birthDate) 기준 7일 후 첫 측정 알림
        baseDate = child.birthDate;
      } else {
        baseDate = list.last.measuredAt; // listAll은 asc → 마지막이 최신
      }

      final scheduleAt =
          DateTime(baseDate.year, baseDate.month, baseDate.day + 7, 9, 0);

      NotificationService.instance.scheduleAt(
        id: notifId,
        title: l10n.notifGrowthWeeklyTitle,
        body: l10n.notifGrowthWeeklyBody,
        when: scheduleAt,
        channelId: 'growth_weekly',
        channelName: 'Growth weekly reminder',
      );
    });
  }

  /// 활성 분유 통의 expectedDaysLeft가 1일 이상이면 (잔량-1일) 시점에 알림 schedule.
  void _scheduleFormulaNotifications(WidgetRef ref, AppLocalizations l10n) {
    final asyncActives =
        ref.watch(activeFormulaInventoriesProvider(child.id));
    asyncActives.whenData((actives) {
      for (final inv in actives) {
        // ID는 자녀 hashcode + 분유 통 id hashcode (같은 통이면 같은 ID)
        final notifId = (child.id.hashCode ^ inv.id.hashCode) & 0x7fffffff;

        // 잔량 stats — provider 결과를 즉시 read (이 시점에 schedule만 하므로 watch 불필요)
        final asyncStats = ref.read(formulaInventoryStatsProvider(inv));
        asyncStats.whenData((stats) {
          // 데이터 부족(>= 999)이면 알림 X
          if (stats.expectedDaysLeft >= 999) {
            NotificationService.instance.cancel(notifId);
            return;
          }
          // 1일분 미만이면 이미 늦음 — 즉시 알림
          // 1일~7일 사이면 (잔량-1일) 시점에 schedule
          final whenDays = stats.expectedDaysLeft - 1.0;
          if (whenDays > 7) {
            // 너무 멀음 — 일단 7일 이내일 때만 schedule
            NotificationService.instance.cancel(notifId);
            return;
          }
          final when = DateTime.now().add(
            Duration(seconds: (whenDays * 86400).round()),
          );
          NotificationService.instance.scheduleAt(
            id: notifId,
            title: l10n.notifFormulaLowTitle,
            body: l10n.notifFormulaLowBody(inv.productName),
            when: when,
            channelId: 'formula',
            channelName: 'Formula',
          );
        });
      }
    });
  }

  /// 미접종 백신 중 권장일 7일 이내인 첫 1건 → 권장일 -1일에 알림.
  void _scheduleVaccineNotifications(WidgetRef ref, AppLocalizations l10n) {
    final asyncSchedules = ref.watch(vaccineSchedulesProvider('KR'));
    final asyncVaccinations = ref.watch(vaccinationsProvider(child.id));

    if (!asyncSchedules.hasValue || !asyncVaccinations.hasValue) return;

    final schedules = asyncSchedules.value!;
    final vaccinations = asyncVaccinations.value!;

    final byCode = <String, Vaccination>{};
    for (final v in vaccinations) {
      byCode['${v.vaccineCode}::${v.doseNumber}'] = v;
    }

    final birthOnly = DateTime(
        child.birthDate.year, child.birthDate.month, child.birthDate.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    VaccineSchedule? upcoming;
    DateTime? recommended;
    for (final s in schedules) {
      final v = byCode['${s.code}::${s.doseNumber}'];
      if (v?.isCompleted ?? false) continue;
      final rec = birthOnly.add(Duration(days: s.recommendedAgeDays));
      final diffDays = rec.difference(today).inDays;
      // 0~7일 사이가 알림 대상
      if (diffDays < 0 || diffDays > 7) continue;
      if (upcoming == null || rec.isBefore(recommended!)) {
        upcoming = s;
        recommended = rec;
      }
    }

    if (upcoming == null || recommended == null) return;

    // ID는 자녀 + 백신 코드+회차로 고정
    final notifId = (child.id.hashCode ^
            '${upcoming.code}::${upcoming.doseNumber}'.hashCode) &
        0x7fffffff;

    // 권장일 1일 전 09:00 알림
    final scheduleAt =
        DateTime(recommended.year, recommended.month, recommended.day - 1, 9);
    NotificationService.instance.scheduleAt(
      id: notifId,
      title: l10n.notifVaccineUpcomingTitle,
      body: l10n.notifVaccineUpcomingBody(upcoming.name),
      when: scheduleAt,
      channelId: 'vaccine',
      channelName: 'Vaccine',
    );
  }
}
