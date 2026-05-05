import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../child/domain/child.dart';
import '../../child/presentation/selected_child_provider.dart';
import '../../inventory/presentation/diaper_inventory_providers.dart';
import '../../inventory/presentation/formula_inventory_providers.dart';
import '../../vaccination/domain/vaccination.dart';
import '../../vaccination/presentation/vaccination_providers.dart';

/// 다가오는 알림 한 줄 요약.
class _AlertItem {
  const _AlertItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.urgent = false,
  });
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool urgent;
}

/// AppBar 우측 종 아이콘 — 다가오는 일정(분유 잔량/사이즈업/접종) 한눈에.
class NotificationBellAction extends ConsumerWidget {
  const NotificationBellAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedChildProvider);
    if (selected == null) return const SizedBox.shrink();

    // 알림 카운트 — 활성 알림 개수만 빠르게 계산.
    final alerts = _collectAlerts(context, ref, selected);
    final count = alerts.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: IconButton(
        tooltip: AppLocalizations.of(context).bellTooltip,
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_outlined),
            if (count > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onError,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        onPressed: () => _showSheet(context, ref, selected),
      ),
    );
  }

  /// 분유 잔량/기저귀 사이즈업/접종 임박 — 우선순위 순으로 알림 모음.
  List<_AlertItem> _collectAlerts(
      BuildContext context, WidgetRef ref, Child child) {
    final l10n = AppLocalizations.of(context);
    final alerts = <_AlertItem>[];

    // 1) 분유 잔량 < 3일
    final asyncActives =
        ref.read(activeFormulaInventoriesProvider(child.id));
    asyncActives.whenData((list) {
      for (final inv in list) {
        final asyncStats = ref.read(formulaInventoryStatsProvider(inv));
        asyncStats.whenData((stats) {
          if (stats.expectedDaysLeft < 3 && stats.expectedDaysLeft >= 0) {
            alerts.add(_AlertItem(
              icon: '🍼',
              title: l10n.bellFormulaLowTitle,
              subtitle: l10n.formulaStatusDaysSupply(
                  stats.expectedDaysLeft.toStringAsFixed(1)),
              urgent: stats.expectedDaysLeft < 1,
              onTap: () =>
                  context.push('/inventory/formula'),
            ));
          }
        });
      }
    });

    // 2) 기저귀 사이즈업 14일 이내
    final asyncForecast =
        ref.read(diaperSizeUpForecastProvider(child.id));
    asyncForecast.whenData((forecast) {
      if (forecast != null &&
          forecast.nextSize != null &&
          forecast.daysToSizeUp <= 14) {
        alerts.add(_AlertItem(
          icon: '📏',
          title: l10n.bellSizeUpTitle,
          subtitle: forecast.daysToSizeUp < 0
              ? l10n.diaperSizeUpOverdue(forecast.nextSize!)
              : l10n.diaperSizeUpDays(
                  forecast.daysToSizeUp, forecast.nextSize!),
          urgent: forecast.daysToSizeUp <= 0,
          onTap: () => context.push('/inventory/diaper'),
        ));
      }
    });

    // 3) 다가오는 접종 14일 이내 (미접종)
    final asyncSchedules = ref.read(vaccineSchedulesProvider('KR'));
    final asyncVaccinations = ref.read(vaccinationsProvider(child.id));
    if (asyncSchedules.hasValue && asyncVaccinations.hasValue) {
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

      for (final s in schedules) {
        final v = byCode['${s.code}::${s.doseNumber}'];
        if (v?.isCompleted ?? false) continue;
        final rec = birthOnly.add(Duration(days: s.recommendedAgeDays));
        final diff = rec.difference(today).inDays;
        if (diff > 14) continue;
        alerts.add(_AlertItem(
          icon: '💉',
          title: s.name,
          subtitle: diff < 0
              ? l10n.upcomingVaccineOverdue(-diff)
              : (diff == 0
                  ? l10n.upcomingVaccineToday
                  : l10n.upcomingVaccineDays(diff)),
          urgent: diff <= 0,
          onTap: () => context.push('/vaccine'),
        ));
      }
    }

    // urgent 먼저
    alerts.sort((a, b) {
      if (a.urgent != b.urgent) return a.urgent ? -1 : 1;
      return 0;
    });
    return alerts;
  }

  Future<void> _showSheet(
      BuildContext context, WidgetRef ref, Child child) async {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) {
        // sheet 안에서도 ref.read로 동일 데이터 사용
        final alerts = _collectAlerts(sheetCtx, ref, child);
        final l10n = AppLocalizations.of(sheetCtx);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md, vertical: Spacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.bellSheetTitle,
                  style: Theme.of(sheetCtx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: Spacing.sm),
                if (alerts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
                    child: Center(
                      child: Text(
                        l10n.bellEmpty,
                        style: Theme.of(sheetCtx).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(sheetCtx)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                  )
                else
                  ...alerts.map((a) => Card(
                        color: a.urgent
                            ? Theme.of(sheetCtx).colorScheme.errorContainer
                            : null,
                        child: ListTile(
                          leading: Text(a.icon, style: const TextStyle(fontSize: 28)),
                          title: Text(a.title),
                          subtitle: Text(a.subtitle),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pop(sheetCtx);
                            a.onTap();
                          },
                        ),
                      )),
                const SizedBox(height: Spacing.md),
              ],
            ),
          ),
        );
      },
    );
  }
}
