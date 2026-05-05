/// 기저귀 사이즈별 적정 체중 범위 + 사이즈업 예측 도메인.
///
/// ── 왜 도메인에 두는가 ────────────────────────────────────────────────
/// 사이즈→체중 범위는 비즈니스 규칙(브랜드 평균, 한국/일본 시장 기준).
/// presentation에 두면 화면마다 흩어져서 관리 어려움 → core domain으로.
///
/// ── 사이즈 범위 (브랜드 공통 평균) ──────────────────────────────────
/// NB(신생아): 0~5kg
/// S: 4~8kg
/// M: 6~11kg
/// L: 9~14kg
/// XL: 12~17kg
/// XXL: 15kg+
///
/// 실제 브랜드(하기스/팬티스/마미포코 등)마다 ±1kg 차이는 있지만,
/// 사이즈업 알림은 "여유 마진(1kg)"으로 흡수.
class DiaperSizeInfo {
  const DiaperSizeInfo({
    required this.size,
    required this.minKg,
    required this.maxKg,
  });

  /// 사이즈 코드. 'NB' / 'S' / 'M' / 'L' / 'XL' / 'XXL'
  final String size;
  final double minKg;
  final double maxKg;

  /// "곧 작아짐" 알림이 뜨는 임계 체중 — maxKg 1kg 전부터.
  /// 예: M(6~11kg)이면 10kg부터 사이즈업 권유.
  double get warningKg => maxKg - 1.0;

  /// 정의된 모든 사이즈. 작은 → 큰 순서.
  static const all = [
    DiaperSizeInfo(size: 'NB', minKg: 0, maxKg: 5),
    DiaperSizeInfo(size: 'S', minKg: 4, maxKg: 8),
    DiaperSizeInfo(size: 'M', minKg: 6, maxKg: 11),
    DiaperSizeInfo(size: 'L', minKg: 9, maxKg: 14),
    DiaperSizeInfo(size: 'XL', minKg: 12, maxKg: 17),
    DiaperSizeInfo(size: 'XXL', minKg: 15, maxKg: 25),
  ];

  /// 사이즈 코드로 조회. 알 수 없으면 null.
  static DiaperSizeInfo? byCode(String size) {
    for (final info in all) {
      if (info.size == size) return info;
    }
    return null;
  }

  /// 다음 사이즈 코드 (없으면 null — XXL은 다음 없음).
  String? get nextSize {
    final i = all.indexWhere((d) => d.size == size);
    if (i < 0 || i >= all.length - 1) return null;
    return all[i + 1].size;
  }
}

/// 사이즈업 예측 결과.
class DiaperSizeForecast {
  const DiaperSizeForecast({
    required this.currentSize,
    required this.currentKg,
    required this.maxKg,
    required this.nextSize,
    required this.daysToSizeUp,
    required this.urgent,
  });

  final String currentSize;
  final double currentKg;
  final double maxKg;
  /// 다음 사이즈 (없으면 null — XXL).
  final String? nextSize;
  /// 권장 사이즈업까지 남은 일수. 999 = 데이터 부족 / 무한.
  /// 음수 = 이미 사이즈업 권장 시점 지남.
  final int daysToSizeUp;
  /// 카드 강조 표시 — 7일 이내거나 이미 초과면 true.
  final bool urgent;
}
