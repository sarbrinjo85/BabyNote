/// 기저귀 재고 한 팩 (diaper_inventories 테이블).
///
/// ── 분유와 차이 ──────────────────────────────────────────────────────
/// - 단위: g(분유) → 매(기저귀, quantity)
/// - size: NB/S/M/L/XL/XXL — 사이즈 업 예측에 사용 (Phase 3 후반)
/// - usageKind: day/night/all — 낮용/밤용/공용
/// - 차감: 분유는 ml/g 환산, 기저귀는 1팩의 quantity에서 사용한 매 차감
///
/// ── 상태 분류 ────────────────────────────────────────────────────────
/// - 사용 중(active): openedAt 있고 depletedAt null
/// - 보관 중(stocked): openedAt null
/// - 소진(depleted): depletedAt 채워짐
class DiaperInventory {
  const DiaperInventory({
    required this.id,
    required this.childId,
    required this.size,
    required this.quantity,
    required this.currency,
    this.brand,
    this.usageKind,
    this.purchasedAt,
    this.priceMinor,
    this.store,
    this.openedAt,
    this.depletedAt,
    this.createdBy,
    this.createdAt,
  });

  final String id;
  final String childId;
  final String? brand;
  /// 'NB' | 'S' | 'M' | 'L' | 'XL' | 'XXL'
  final String size;
  /// 1팩의 매수 (예: 60매)
  final int quantity;
  /// 'day' | 'night' | 'all' (선택)
  final String? usageKind;
  final DateTime? purchasedAt;
  final int? priceMinor;
  final String currency;
  final String? store;
  final DateTime? openedAt;
  final DateTime? depletedAt;
  final String? createdBy;
  final DateTime? createdAt;

  bool get isActive => openedAt != null && depletedAt == null;
  bool get isStocked => openedAt == null;
  bool get isDepleted => depletedAt != null;

  factory DiaperInventory.fromMap(Map<String, dynamic> map) {
    return DiaperInventory(
      id: map['id'] as String,
      childId: map['child_id'] as String,
      brand: map['brand'] as String?,
      size: map['size'] as String,
      quantity: map['quantity'] as int,
      usageKind: map['usage_kind'] as String?,
      purchasedAt: map['purchased_at'] != null
          ? DateTime.parse(map['purchased_at'] as String)
          : null,
      priceMinor: map['price_minor'] as int?,
      currency: map['currency'] as String? ?? 'KRW',
      store: map['store'] as String?,
      openedAt: map['opened_at'] != null
          ? DateTime.parse(map['opened_at'] as String)
          : null,
      depletedAt: map['depleted_at'] != null
          ? DateTime.parse(map['depleted_at'] as String)
          : null,
      createdBy: map['created_by'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertMap({required String createdBy}) {
    return {
      'child_id': childId,
      'created_by': createdBy,
      'size': size,
      'quantity': quantity,
      if (brand != null && brand!.isNotEmpty) 'brand': brand,
      if (usageKind != null) 'usage_kind': usageKind,
      if (purchasedAt != null) 'purchased_at': _date(purchasedAt!),
      if (priceMinor != null) 'price_minor': priceMinor,
      'currency': currency,
      if (store != null && store!.isNotEmpty) 'store': store,
      if (openedAt != null) 'opened_at': _date(openedAt!),
    };
  }

  static String _date(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }
}


/// 기저귀 통의 잔량/사용/소진 예상 통계.
///
/// 분유와 다르게 단위가 매수(int).
class DiaperInventoryStats {
  const DiaperInventoryStats({
    required this.inventory,
    required this.consumedCount,
    required this.dailyAvgCount,
    required this.expectedDaysLeft,
    required this.confidence,
  });

  final DiaperInventory inventory;
  final int consumedCount;
  final double dailyAvgCount;
  final double expectedDaysLeft;
  final String confidence;

  int get remainingCount {
    final r = inventory.quantity - consumedCount;
    return r < 0 ? 0 : r;
  }

  double get remainingRatio {
    if (inventory.quantity == 0) return 0;
    return (remainingCount / inventory.quantity).clamp(0.0, 1.0);
  }
}
