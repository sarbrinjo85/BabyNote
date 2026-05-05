/// WHO Child Growth Standards — 0~24개월 weight-for-age 백분위.
///
/// ── 출처 ─────────────────────────────────────────────────────────────
/// World Health Organization Multicentre Growth Reference Study (MGRS).
/// 공식 차트: https://www.who.int/tools/child-growth-standards/standards/weight-for-age
/// 본 데이터는 P3/P50/P97 라인만 추출 (의료진 권장 minimum 라인 3종).
///
/// ── 단위/기준 ────────────────────────────────────────────────────────
/// month: 0~24 (월령), weight: kg.
/// boy / girl 별로 분리. 'other'(일부 사용자)는 boy 표를 fallback으로 표시.
///
/// ── 백분위 의미 ──────────────────────────────────────────────────────
/// P3  (3% 라인): 같은 월령 100명 중 가벼운 쪽 3번째. 이보다 아래는 의사 상담 권장.
/// P50 (중간값): 평균.
/// P97 (97% 라인): 같은 월령 100명 중 무거운 쪽 3번째. 이보다 위도 의사 상담 권장.
///
/// 차트는 P3~P97 영역을 음영으로 깔고 자녀 점을 그 위에 표시 → 정상 범위 시각화.
class WhoPercentilePoint {
  const WhoPercentilePoint({
    required this.monthAge,
    required this.p3,
    required this.p50,
    required this.p97,
  });

  final int monthAge;
  final double p3;
  final double p50;
  final double p97;
}

class WhoWeightForAge {
  const WhoWeightForAge._();

  /// 남아 (Boys) — 월별 P3/P50/P97 (kg).
  static const boys = <WhoPercentilePoint>[
    WhoPercentilePoint(monthAge: 0, p3: 2.5, p50: 3.3, p97: 4.4),
    WhoPercentilePoint(monthAge: 1, p3: 3.4, p50: 4.5, p97: 5.8),
    WhoPercentilePoint(monthAge: 2, p3: 4.4, p50: 5.6, p97: 7.1),
    WhoPercentilePoint(monthAge: 3, p3: 5.1, p50: 6.4, p97: 8.0),
    WhoPercentilePoint(monthAge: 4, p3: 5.6, p50: 7.0, p97: 8.7),
    WhoPercentilePoint(monthAge: 5, p3: 6.1, p50: 7.5, p97: 9.3),
    WhoPercentilePoint(monthAge: 6, p3: 6.4, p50: 7.9, p97: 9.8),
    WhoPercentilePoint(monthAge: 7, p3: 6.7, p50: 8.3, p97: 10.3),
    WhoPercentilePoint(monthAge: 8, p3: 6.9, p50: 8.6, p97: 10.7),
    WhoPercentilePoint(monthAge: 9, p3: 7.1, p50: 8.9, p97: 11.0),
    WhoPercentilePoint(monthAge: 10, p3: 7.4, p50: 9.2, p97: 11.4),
    WhoPercentilePoint(monthAge: 11, p3: 7.6, p50: 9.4, p97: 11.7),
    WhoPercentilePoint(monthAge: 12, p3: 7.7, p50: 9.6, p97: 12.0),
    WhoPercentilePoint(monthAge: 15, p3: 8.3, p50: 10.3, p97: 12.8),
    WhoPercentilePoint(monthAge: 18, p3: 8.8, p50: 10.9, p97: 13.7),
    WhoPercentilePoint(monthAge: 21, p3: 9.2, p50: 11.5, p97: 14.5),
    WhoPercentilePoint(monthAge: 24, p3: 9.7, p50: 12.2, p97: 15.3),
  ];

  /// 여아 (Girls) — 월별 P3/P50/P97 (kg).
  static const girls = <WhoPercentilePoint>[
    WhoPercentilePoint(monthAge: 0, p3: 2.4, p50: 3.2, p97: 4.2),
    WhoPercentilePoint(monthAge: 1, p3: 3.2, p50: 4.2, p97: 5.5),
    WhoPercentilePoint(monthAge: 2, p3: 3.9, p50: 5.1, p97: 6.6),
    WhoPercentilePoint(monthAge: 3, p3: 4.5, p50: 5.8, p97: 7.5),
    WhoPercentilePoint(monthAge: 4, p3: 5.0, p50: 6.4, p97: 8.2),
    WhoPercentilePoint(monthAge: 5, p3: 5.4, p50: 6.9, p97: 8.8),
    WhoPercentilePoint(monthAge: 6, p3: 5.7, p50: 7.3, p97: 9.3),
    WhoPercentilePoint(monthAge: 7, p3: 6.0, p50: 7.6, p97: 9.8),
    WhoPercentilePoint(monthAge: 8, p3: 6.3, p50: 7.9, p97: 10.2),
    WhoPercentilePoint(monthAge: 9, p3: 6.5, p50: 8.2, p97: 10.5),
    WhoPercentilePoint(monthAge: 10, p3: 6.7, p50: 8.5, p97: 10.9),
    WhoPercentilePoint(monthAge: 11, p3: 6.9, p50: 8.7, p97: 11.2),
    WhoPercentilePoint(monthAge: 12, p3: 7.0, p50: 8.9, p97: 11.5),
    WhoPercentilePoint(monthAge: 15, p3: 7.6, p50: 9.6, p97: 12.4),
    WhoPercentilePoint(monthAge: 18, p3: 8.1, p50: 10.2, p97: 13.2),
    WhoPercentilePoint(monthAge: 21, p3: 8.6, p50: 10.9, p97: 14.0),
    WhoPercentilePoint(monthAge: 24, p3: 9.0, p50: 11.5, p97: 14.8),
  ];

  /// 자녀 성별에 맞는 표 반환. 'other' 또는 unknown은 boys로 fallback (변환 표시 용도).
  static List<WhoPercentilePoint> forGender(String? gender) {
    if (gender == 'female') return girls;
    return boys;
  }

  /// 월 단위 정수가 아닌 임의 시점(예: 7.4개월)에 대한 P3/P50/P97 선형 보간.
  /// 두 인접 데이터 포인트 사이를 선형 보간 — 차트 라인을 부드럽게 그릴 때 사용.
  static WhoPercentilePoint? interpolate(
    List<WhoPercentilePoint> table,
    double monthAge,
  ) {
    if (table.isEmpty) return null;
    if (monthAge <= table.first.monthAge) return table.first;
    if (monthAge >= table.last.monthAge) return table.last;

    for (var i = 0; i < table.length - 1; i++) {
      final a = table[i];
      final b = table[i + 1];
      if (monthAge >= a.monthAge && monthAge <= b.monthAge) {
        final span = (b.monthAge - a.monthAge).toDouble();
        if (span <= 0) return a;
        final t = (monthAge - a.monthAge) / span;
        return WhoPercentilePoint(
          monthAge: monthAge.round(),
          p3: a.p3 + (b.p3 - a.p3) * t,
          p50: a.p50 + (b.p50 - a.p50) * t,
          p97: a.p97 + (b.p97 - a.p97) * t,
        );
      }
    }
    return null;
  }
}
