import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../child/domain/child.dart';
import '../../inventory/presentation/diaper_inventory_providers.dart';
import '../../inventory/presentation/formula_inventory_providers.dart';
import '../../vaccination/domain/vaccination.dart';
import '../../vaccination/presentation/vaccination_providers.dart';

/// AppBar 바로 아래 한 줄 컴팩트 알림 배너.
///
/// 분유 < 3일 / 기저귀 사이즈업 ≤ 14일 / 접종 ≤ 7일 중 하나라도 있으면 표시,
/// 없으면 SizedBox.shrink. 가장 시급한 것 하나만 노출(공간 절약).
class AlertBanner extends ConsumerWidget {
  const AlertBanner({super.key, required this.child});
  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // 1) 분유 잔량 — 활성 통의 첫 번째 stats 확인
    String? formulaMsg;
    final asyncActives =
        ref.watch(activeFormulaInventoriesProvider(child.id));
    asyncActives.whenData((list) {
      for (final inv in list) {
        final asyncStats = ref.read(formulaInventoryStatsProvider(inv));
        asyncStats.whenData((s) {
          if (s.expectedDaysLeft < 3 && s.expectedDaysLeft >= 0) {
            formulaMsg = '🍼 ${l10n.formulaStatusDaysSupply(s.expectedDaysLeft.toStringAsFixed(1))}';
          }
        });
      }
    });

    // 2) 사이즈업 — 14일 이내
    String? sizeUpMsg;
    final asyncForecast =
        ref.watch(diaperSizeUpForecastProvider(child.id));
    asyncForecast.whenData((f) {
      if (f != null && f.nextSize != null && f.daysToSizeUp <= 14) {
        sizeUpMsg = f.daysToSizeUp < 0
            ? '📏 ${l10n.diaperSizeUpOverdue(f.nextSize!)}'
            : '📏 ${l10n.diaperSizeUpDays(f.daysToSizeUp, f.nextSize!)}';
      }
    });

    // 3) 다가오는 접종 — 7일 이내
    String? vaccineMsg;
    final asyncSchedules = ref.watch(vaccineSchedulesProvider('KR'));
    final asyncVaccinations = ref.watch(vaccinationsProvider(child.id));
    if (asyncSchedules.hasValue && asyncVaccinations.hasValue) {
      final schedules = asyncSchedules.value!;
      final vaccinations = asyncVaccinations.value!;
      final byCode = <String, Vaccination>{};
      for (final v in vaccinations) {
        byCode['${v.vaccineCode}::${v.doseNumber}'] = v;
      }
      final birth = DateTime(
          child.birthDate.year, child.birthDate.month, child.birthDate.day);
      final today = DateTime.now();
      final todayD = DateTime(today.year, today.month, today.day);
      for (final s in schedules) {
        final v = byCode['${s.code}::${s.doseNumber}'];
        if (v?.isCompleted ?? false) continue;
        final rec = birth.add(Duration(days: s.recommendedAgeDays));
        final diff = rec.difference(todayD).inDays;
        if (diff > 7) continue;
        vaccineMsg = diff < 0
            ? '💉 ${s.name} ${l10n.upcomingVaccineOverdue(-diff)}'
            : (diff == 0
                ? '💉 ${s.name} ${l10n.upcomingVaccineToday}'
                : '💉 ${s.name} ${l10n.upcomingVaccineDays(diff)}');
        break;
      }
    }

    // 우선순위: vaccine overdue > formula < 3일 > sizeUp > vaccine 미래
    final msg = vaccineMsg ?? formulaMsg ?? sizeUpMsg;
    if (msg == null) return const SizedBox.shrink();

    return InkWell(
      onTap: () {
        // 가장 관련성 높은 화면으로 이동
        if (vaccineMsg != null) {
          context.push('/vaccine');
        } else if (formulaMsg != null) {
          context.push('/inventory/formula');
        } else {
          context.push('/inventory/diaper');
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md, vertical: Spacing.xs),
        color: theme.colorScheme.errorContainer,
        child: Row(
          children: [
            Expanded(
              child: Text(
                msg,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.chevron_right,
                color: theme.colorScheme.onErrorContainer, size: 20),
          ],
        ),
      ),
    );
  }
}
