import 'dart:math' as math;

import 'who_lms_data.dart';

/// 자녀 측정값을 WHO 표준에 비교한 결과.
class GrowthPercentile {
  const GrowthPercentile({
    required this.metric,
    required this.zScore,
    required this.percentile,
    required this.band,
  });

  final WhoMetric metric;
  final double zScore;
  /// 0~100 (예: 50.0 = median)
  final double percentile;
  /// 'low' (P<3), 'belowAvg' (P3-P15), 'avg' (P15-P85),
  /// 'aboveAvg' (P85-P97), 'high' (P>97)
  final String band;

  /// 사용자 친화 라벨.
  ///   P50 정확히 → "또래 평균"
  ///   P > 50    → "상위 N%"   (위로부터 몇 %)
  ///   P < 50    → "하위 N%"   (아래로부터 몇 %)
  String get displayLabel {
    final r = percentile.round();
    if (r == 50) return '또래 평균';
    if (r > 50) return '상위 ${100 - r}%';
    return '하위 $r%';
  }

  /// 자녀 카드용 한 줄 코멘트.
  String get comment {
    switch (band) {
      case 'low':
        return '또래보다 작은 편 (참고)';
      case 'belowAvg':
        return '또래보다 살짝 작은 편';
      case 'avg':
        return '또래 평균과 비슷해요';
      case 'aboveAvg':
        return '또래보다 살짝 큰 편';
      case 'high':
        return '또래보다 큰 편 (참고)';
      default:
        return '';
    }
  }
}

/// WHO 표준에 측정값을 매핑하는 계산 서비스.
///
/// ── 사용 ─────────────────────────────────────────────────────────────
/// final p = WhoGrowthService.compute(
///   metric: WhoMetric.weight,
///   isMale: true,
///   ageInDays: 95,
///   value: 5.4, // kg
/// );
/// p.percentile // 52.3
/// p.comment    // "또래 평균과 비슷해요"
class WhoGrowthService {
  const WhoGrowthService._();

  /// 0-24개월 범위 밖이거나 데이터 없으면 null 반환.
  static GrowthPercentile? compute({
    required WhoMetric metric,
    required bool isMale,
    required int ageInDays,
    required double value,
  }) {
    final ageMonths = ageInDays / 30.4375;
    if (ageMonths < 0 || ageMonths > 24) return null;
    final table = whoTable(metric, isMale: isMale);
    final lms = _interpolate(table, ageMonths);
    if (lms == null) return null;

    final z = _zScore(value, lms.l, lms.m, lms.s);
    final p = _zToPercentile(z);
    final band = _classify(p);

    return GrowthPercentile(
      metric: metric,
      zScore: z,
      percentile: p,
      band: band,
    );
  }

  /// 표 사이 월령은 선형 보간.
  static _LmsValues? _interpolate(List<LmsRow> table, double month) {
    if (month <= table.first.month.toDouble()) {
      final r = table.first;
      return _LmsValues(r.l, r.m, r.s);
    }
    if (month >= table.last.month.toDouble()) {
      final r = table.last;
      return _LmsValues(r.l, r.m, r.s);
    }
    for (var i = 0; i < table.length - 1; i++) {
      final lo = table[i];
      final hi = table[i + 1];
      if (month >= lo.month && month <= hi.month) {
        final t = (month - lo.month) / (hi.month - lo.month);
        return _LmsValues(
          lo.l + (hi.l - lo.l) * t,
          lo.m + (hi.m - lo.m) * t,
          lo.s + (hi.s - lo.s) * t,
        );
      }
    }
    return null;
  }

  /// Box-Cox transformation (LMS) — Z-score 계산.
  static double _zScore(double x, double l, double m, double s) {
    if (l.abs() < 1e-9) {
      return math.log(x / m) / s;
    }
    return (math.pow(x / m, l).toDouble() - 1) / (l * s);
  }

  /// Z → percentile (0..100). 표준 정규분포 CDF.
  /// erf Abramowitz & Stegun 7.1.26 근사.
  static double _zToPercentile(double z) {
    final p = 0.5 * (1 + _erf(z / math.sqrt(2)));
    return (p * 100).clamp(0.0, 100.0);
  }

  static double _erf(double x) {
    const a1 = 0.254829592;
    const a2 = -0.284496736;
    const a3 = 1.421413741;
    const a4 = -1.453152027;
    const a5 = 1.061405429;
    const p = 0.3275911;
    final sign = x < 0 ? -1.0 : 1.0;
    final ax = x.abs();
    final t = 1.0 / (1.0 + p * ax);
    final y = 1.0 -
        (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t *
            math.exp(-ax * ax);
    return sign * y;
  }

  static String _classify(double p) {
    if (p < 3) return 'low';
    if (p < 15) return 'belowAvg';
    if (p < 85) return 'avg';
    if (p < 97) return 'aboveAvg';
    return 'high';
  }

  /// 차트용: 특정 percentile의 값(역계산).
  /// p = 0..100. WHO 표 + LMS 역변환.
  static double? valueAtPercentile({
    required WhoMetric metric,
    required bool isMale,
    required int ageInDays,
    required double percentile,
  }) {
    final ageMonths = ageInDays / 30.4375;
    if (ageMonths < 0 || ageMonths > 24) return null;
    final table = whoTable(metric, isMale: isMale);
    final lms = _interpolate(table, ageMonths);
    if (lms == null) return null;

    final z = _percentileToZ(percentile);
    if (lms.l.abs() < 1e-9) {
      return lms.m * math.exp(z * lms.s);
    }
    return lms.m * math.pow(1 + lms.l * lms.s * z, 1 / lms.l).toDouble();
  }

  /// percentile → Z. 정규분포 inverse CDF 근사 (Beasley-Springer-Moro).
  static double _percentileToZ(double p) {
    final q = (p / 100).clamp(0.0001, 0.9999);
    // 간이 근사: Acklam's algorithm
    const a = [
      -3.969683028665376e+01,
      2.209460984245205e+02,
      -2.759285104469687e+02,
      1.383577518672690e+02,
      -3.066479806614716e+01,
      2.506628277459239e+00
    ];
    const b = [
      -5.447609879822406e+01,
      1.615858368580409e+02,
      -1.556989798598866e+02,
      6.680131188771972e+01,
      -1.328068155288572e+01
    ];
    const c = [
      -7.784894002430293e-03,
      -3.223964580411365e-01,
      -2.400758277161838e+00,
      -2.549732539343734e+00,
      4.374664141464968e+00,
      2.938163982698783e+00
    ];
    const d = [
      7.784695709041462e-03,
      3.224671290700398e-01,
      2.445134137142996e+00,
      3.754408661907416e+00
    ];
    const pLow = 0.02425;
    const pHigh = 1 - pLow;
    double x;
    if (q < pLow) {
      final ql = math.sqrt(-2 * math.log(q));
      x = (((((c[0] * ql + c[1]) * ql + c[2]) * ql + c[3]) * ql + c[4]) * ql +
              c[5]) /
          ((((d[0] * ql + d[1]) * ql + d[2]) * ql + d[3]) * ql + 1);
    } else if (q <= pHigh) {
      final ql = q - 0.5;
      final r = ql * ql;
      x = (((((a[0] * r + a[1]) * r + a[2]) * r + a[3]) * r + a[4]) * r +
              a[5]) *
          ql /
          (((((b[0] * r + b[1]) * r + b[2]) * r + b[3]) * r + b[4]) * r + 1);
    } else {
      final ql = math.sqrt(-2 * math.log(1 - q));
      x = -(((((c[0] * ql + c[1]) * ql + c[2]) * ql + c[3]) * ql + c[4]) * ql +
              c[5]) /
          ((((d[0] * ql + d[1]) * ql + d[2]) * ql + d[3]) * ql + 1);
    }
    return x;
  }
}

class _LmsValues {
  const _LmsValues(this.l, this.m, this.s);
  final double l;
  final double m;
  final double s;
}
