import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../child/domain/child.dart';
import '../../growth/data/who_growth_service.dart';
import '../../growth/data/who_lms_data.dart';
import '../../growth/domain/growth.dart';
import '../../growth/presentation/growth_providers.dart';

/// 자녀 정보 큰 카드 — 이름/생후 + 최신 성장 데이터 (체중/키/머리둘레).
///
/// 탭하면 자녀 편집 화면. 성장 데이터 영역은 latestGrowth(가장 최근 측정값)에서.
class ChildInfoCard extends ConsumerWidget {
  const ChildInfoCard({super.key, required this.child});
  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final asyncGrowths = ref.watch(growthsProvider(child.id));

    Growth? latest;
    asyncGrowths.whenData((list) {
      if (list.isNotEmpty) latest = list.last; // listAll은 asc → 마지막이 최신
    });

    final genderLabel = _genderLabel(l10n, child.gender);
    final ageDays = child.ageInDays(DateTime.now());
    final isMale = child.gender == 'male';

    GrowthPercentile? pctFor(WhoMetric m, double? value) =>
        value == null
            ? null
            : WhoGrowthService.compute(
                metric: m,
                isMale: isMale,
                ageInDays: ageDays,
                value: value,
              );
    final pctW = pctFor(
        WhoMetric.weight, latest?.weightG == null ? null : latest!.weightG! / 1000);
    final pctH = pctFor(
        WhoMetric.height, latest?.heightMm == null ? null : latest!.heightMm! / 10);
    final pctC = pctFor(WhoMetric.headCirc,
        latest?.headCircumferenceMm == null ? null : latest!.headCircumferenceMm! / 10);

    return Card(
      // 코랄핑크 톤의 옅은 테두리로 자녀 섹션 강조.
      shape: RoundedRectangleBorder(
        borderRadius: Radii.brMd,
        side: BorderSide(
          color: BrandColors.seed.withValues(alpha: 0.6),
          width: 1.2,
        ),
      ),
      child: InkWell(
        // 자녀 카드 단축 탭 → 편집, 길게 누름 → 성장 차트
        onTap: () => context.push('/child/edit', extra: child),
        onLongPress: () => context.push('/growth/chart', extra: child),
        borderRadius: Radii.brMd,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 좌측: 아이콘 + 이름 + 생후 일수
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.child_care, size: 20),
                        const SizedBox(width: Spacing.xs),
                        Expanded(
                          child: Text(
                            child.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.homeChildSubtitle(genderLabel, ageDays),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // 우측: 성장 3개 (체중/키/머리둘레)
              Expanded(
                flex: 4,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _GrowthMetric(
                      icon: '⚖️',
                      label: l10n.growthWeightLabel,
                      value: latest?.weightG != null
                          ? '${(latest!.weightG! / 1000).toStringAsFixed(2)}kg'
                          : '—',
                      pct: pctW,
                    ),
                    _GrowthMetric(
                      icon: '📏',
                      label: l10n.growthHeightLabel,
                      value: latest?.heightMm != null
                          ? '${(latest!.heightMm! / 10).toStringAsFixed(1)}cm'
                          : '—',
                      pct: pctH,
                    ),
                    _GrowthMetric(
                      icon: '🧢',
                      label: l10n.growthHeadLabel,
                      value: latest?.headCircumferenceMm != null
                          ? '${(latest!.headCircumferenceMm! / 10).toStringAsFixed(1)}cm'
                          : '—',
                      pct: pctC,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _genderLabel(AppLocalizations l10n, String? g) {
    switch (g) {
      case 'female':
        return l10n.childGenderFemale;
      case 'male':
        return l10n.childGenderMale;
      case 'other':
        return l10n.childGenderOther;
      default:
        return l10n.childGenderUnset;
    }
  }
}

class _GrowthMetric extends StatelessWidget {
  const _GrowthMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.pct,
  });
  final String icon;
  final String label;
  final String value;
  final GrowthPercentile? pct;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color bandColor() {
      if (pct == null) return theme.colorScheme.onSurfaceVariant;
      switch (pct!.band) {
        case 'low':
        case 'high':
          return theme.colorScheme.error;
        case 'belowAvg':
        case 'aboveAvg':
          return const Color(0xFFE89A4F); // 주의 amber
        default:
          return const Color(0xFF7BC9A3); // success green
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
        if (pct != null) ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: bandColor().withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'P${pct!.percentile.round()}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: bandColor(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
