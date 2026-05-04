/// 분유 재고 한 통 (formula_inventories 테이블).
///
/// ── 단위 약속 ────────────────────────────────────────────────────────
/// - containerGrams: 1통 용량 (g)
/// - mlPerGram: 1g당 환산 ml (제품마다 다름. default 7.0)
/// - priceMinor: 가격을 minor unit 정수로 (KRW는 그대로 원, USD/JPY 등은 cent/sen 단위)
///
/// ── 상태 분류 ────────────────────────────────────────────────────────
/// - 사용 중(active): openedAt이 있고 depletedAt이 null
/// - 보관 중(stocked): openedAt이 null (아직 개봉 전)
/// - 소진(depleted): depletedAt이 채워짐
///
/// ── 잔량 계산 (Phase 3 후반에서 사용) ─────────────────────────────
/// 사용 중일 때 잔량 = containerGrams - 누적 소비량(g).
/// 누적 소비량은 feedings.amount_ml 중 이 inventory와 연결된 것들의 합 / mlPerGram.
class FormulaInventory {
  const FormulaInventory({
    required this.id,
    required this.childId,
    required this.productName,
    required this.containerGrams,
    required this.mlPerGram,
    required this.currency,
    this.brand,
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
  final String productName;
  final String? brand;
  final int containerGrams;
  final double mlPerGram;
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

  factory FormulaInventory.fromMap(Map<String, dynamic> map) {
    return FormulaInventory(
      id: map['id'] as String,
      childId: map['child_id'] as String,
      productName: map['product_name'] as String,
      brand: map['brand'] as String?,
      containerGrams: map['container_grams'] as int,
      mlPerGram: (map['ml_per_gram'] as num).toDouble(),
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
      'product_name': productName,
      if (brand != null && brand!.isNotEmpty) 'brand': brand,
      'container_grams': containerGrams,
      'ml_per_gram': mlPerGram,
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
