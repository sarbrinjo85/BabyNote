import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../inventory/domain/diaper_size.dart';
import '../../inventory/presentation/diaper_inventory_providers.dart';

/// 홈 화면용 "기저귀 사이즈업 예측" 카드 — 차별화 ③의 마지막 조각.
///
/// ── 표시 조건 ────────────────────────────────────────────────────────
/// diaperSizeUpForecastProvider 결과가:
/// - null (활성 팩 없음 / 체중 기록 없음 / XXL 사용 중) → 카드 숨김
/// - daysToSizeUp > 21 (3주 이상 여유) → 카드 숨김 (홈 깔끔하게)
/// - 그 외 → 카드 표시
///
/// 21일 이내 미래거나 이미 사이즈업 권장 시점 지난 경우만 표시.
/// 알림 임팩트는 N1(다가오는 접종) 카드와 동일한 패턴.
class DiaperSizeUpCard extends ConsumerWidget {
  const DiaperSizeUpCard({super.key, required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncForecast = ref.watch(diaperSizeUpForecastProvider(childId));
    return asyncForecast.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (forecast) {
        // null = 데이터 부족, 표시 X
        if (forecast == null) return const SizedBox.shrink();
        // 다음 사이즈 없음(XXL이 현재 사이즈) → 더 이상 사이즈업 없음
        if (forecast.nextSize == null) return const SizedBox.shrink();
        // 21일 이상 여유 → 표시 X (3주는 여유 있음)
        if (forecast.daysToSizeUp > 21) return const SizedBox.shrink();

        return _Card(forecast: forecast);
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.forecast});

  final DiaperSizeForecast forecast;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final urgent = forecast.urgent;
    final overdue = forecast.daysToSizeUp < 0;
    // nextSize null 체크는 호출 측에서 끝내고 들어오므로 ! 안전.
    final nextSize = forecast.nextSize!;

    final String statusText;
    if (overdue) {
      statusText = l10n.diaperSizeUpOverdue(nextSize);
    } else if (urgent) {
      statusText = l10n.diaperSizeUpUrgent(
        forecast.currentSize,
        nextSize,
      );
    } else {
      statusText = l10n.diaperSizeUpDays(
        forecast.daysToSizeUp,
        nextSize,
      );
    }

    final subText = l10n.diaperSizeUpCurrentWeight(
      forecast.currentKg.toStringAsFixed(2),
      forecast.currentSize,
      forecast.maxKg.toStringAsFixed(0),
    );

    return Card(
      color: urgent || overdue
          ? theme.colorScheme.errorContainer
          : theme.colorScheme.secondaryContainer,
      child: InkWell(
        // 탭 → 기저귀 재고 화면 (사이즈업 후 새 사이즈 등록 유도)
        onTap: () => context.push('/inventory/diaper'),
        borderRadius: Radii.brMd,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            children: [
              Text(urgent || overdue ? '⚠️' : '📏',
                  style: const TextStyle(fontSize: 32)),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.diaperSizeUpTitle,
                        style: theme.textTheme.labelMedium),
                    Text(
                      statusText,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: urgent || overdue
                            ? theme.colorScheme.onErrorContainer
                            : theme.colorScheme.onSecondaryContainer,
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
