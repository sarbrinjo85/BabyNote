import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../child/domain/child.dart';
import '../data/who_growth_service.dart';
import '../data/who_lms_data.dart';
import 'growth_providers.dart';

/// 성장 차트 화면 — 자녀 측정값을 WHO P3/15/50/85/97 곡선과 비교.
///
/// ── 동작 ─────────────────────────────────────────────────────────────
/// 상단 SegmentedButton으로 metric 전환 (체중/키/머리둘레).
/// fl_chart LineChart에 5개 percentile 곡선 + 자녀 측정점 산점.
/// 0-24개월 범위 데이터만 (MVP).
class GrowthChartPage extends ConsumerStatefulWidget {
  const GrowthChartPage({super.key, required this.child});
  final Child child;

  @override
  ConsumerState<GrowthChartPage> createState() => _GrowthChartPageState();
}

class _GrowthChartPageState extends ConsumerState<GrowthChartPage> {
  WhoMetric _metric = WhoMetric.weight;

  @override
  Widget build(BuildContext context) {
    final asyncGrowths = ref.watch(growthsProvider(widget.child.id));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('${widget.child.name} 성장 차트')),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── metric 전환 ─────────────────────────────────────
              SegmentedButton<WhoMetric>(
                segments: const [
                  ButtonSegment(value: WhoMetric.weight, label: Text('체중')),
                  ButtonSegment(value: WhoMetric.height, label: Text('키')),
                  ButtonSegment(
                      value: WhoMetric.headCirc, label: Text('머리둘레')),
                ],
                selected: {_metric},
                onSelectionChanged: (s) => setState(() => _metric = s.first),
              ),
              const SizedBox(height: Spacing.md),

              // ── 차트 ─────────────────────────────────────────────
              Expanded(
                child: asyncGrowths.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('로드 실패: $e')),
                  data: (list) => _Chart(
                    child: widget.child,
                    metric: _metric,
                    growths: list,
                  ),
                ),
              ),

              // ── 범례 + 면책 ──────────────────────────────────────
              const SizedBox(height: Spacing.sm),
              Wrap(
                spacing: Spacing.md,
                runSpacing: 4,
                children: [
                  _LegendDot(color: theme.colorScheme.primary, label: '내 아이'),
                  _LegendDot(
                      color: theme.colorScheme.error,
                      label: '상·하위 3% (외곽)'),
                  _LegendDot(
                      color: theme.colorScheme.tertiary,
                      label: '상·하위 15%'),
                  _LegendDot(
                      color: theme.colorScheme.onSurfaceVariant,
                      label: '또래 평균(중앙)'),
                ],
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                'WHO 0~24개월 성장 표준 기준. 의료 진단 대체 아님.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({
    required this.child,
    required this.metric,
    required this.growths,
  });

  final Child child;
  final WhoMetric metric;
  final List growths;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMale = child.gender == 'male';

    // 0-24개월 = 0-730일. x축은 일수.
    const ageMin = 0.0;
    const ageMax = 730.0;
    const step = 30.0; // 표 사이 30일 간격

    List<FlSpot> percentileSpots(double pct) {
      final spots = <FlSpot>[];
      for (var d = ageMin; d <= ageMax; d += step) {
        final v = WhoGrowthService.valueAtPercentile(
          metric: metric,
          isMale: isMale,
          ageInDays: d.toInt(),
          percentile: pct,
        );
        if (v != null) spots.add(FlSpot(d, v));
      }
      return spots;
    }

    LineChartBarData line(double pct, Color color, {double width = 1.2,
        bool dashed = false}) {
      return LineChartBarData(
        spots: percentileSpots(pct),
        color: color,
        barWidth: width,
        isCurved: true,
        dotData: const FlDotData(show: false),
        dashArray: dashed ? [4, 3] : null,
      );
    }

    // 자녀 측정점들 (생후 일수 기준)
    final childSpots = <FlSpot>[];
    for (final g in growths) {
      final ageDays = child.ageInDays(g.measuredAt);
      if (ageDays < 0 || ageDays > ageMax) continue;
      double? value;
      switch (metric) {
        case WhoMetric.weight:
          value = g.weightG == null ? null : g.weightG / 1000.0;
          break;
        case WhoMetric.height:
          value = g.heightMm == null ? null : g.heightMm / 10.0;
          break;
        case WhoMetric.headCirc:
          value = g.headCircumferenceMm == null
              ? null
              : g.headCircumferenceMm / 10.0;
          break;
      }
      if (value != null) childSpots.add(FlSpot(ageDays.toDouble(), value));
    }
    childSpots.sort((a, b) => a.x.compareTo(b.x));

    final unit = switch (metric) {
      WhoMetric.weight => 'kg',
      WhoMetric.height => 'cm',
      WhoMetric.headCirc => 'cm',
    };

    return LineChart(
      LineChartData(
        minX: ageMin,
        maxX: ageMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: _yInterval(metric),
          verticalInterval: 90, // 3개월 간격
          getDrawingHorizontalLine: (_) => FlLine(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            strokeWidth: 0.5,
          ),
          getDrawingVerticalLine: (_) => FlLine(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: _yInterval(metric),
              getTitlesWidget: (v, _) => Text(
                '${v.toStringAsFixed(0)}$unit',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 90,
              getTitlesWidget: (v, _) => Text(
                '${(v / 30).round()}m',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
              color: theme.colorScheme.outlineVariant, width: 0.6),
        ),
        lineBarsData: [
          line(3, theme.colorScheme.error, dashed: true),
          line(15, theme.colorScheme.tertiary),
          line(50, theme.colorScheme.onSurfaceVariant, width: 1.4),
          line(85, theme.colorScheme.tertiary),
          line(97, theme.colorScheme.error, dashed: true),
          // 자녀 측정점 + 잇는 선
          LineChartBarData(
            spots: childSpots,
            color: theme.colorScheme.primary,
            barWidth: 2.5,
            isCurved: false,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                radius: 4,
                color: theme.colorScheme.primary,
                strokeWidth: 1.5,
                strokeColor: theme.colorScheme.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static double _yInterval(WhoMetric m) {
    switch (m) {
      case WhoMetric.weight:
        return 2; // 2kg
      case WhoMetric.height:
        return 10; // 10cm
      case WhoMetric.headCirc:
        return 2; // 2cm
    }
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
