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
/// 분유 형태 — 가루(powder) vs 액상(liquid/RTF).
enum FormulaForm {
  powder,
  liquid;

  String get value => name; // db 저장값 그대로
  static FormulaForm fromString(String? s) =>
      s == 'powder' ? FormulaForm.powder : FormulaForm.liquid;
}

class FormulaInventory {
  const FormulaInventory({
    required this.id,
    required this.childId,
    required this.productName,
    required this.containerGrams,
    required this.mlPerGram,
    required this.currency,
    this.form = FormulaForm.liquid,
    this.gPerScoop = 4.4,
    this.mlPerScoop = 30.0,
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
  /// 형태(가루/액상). 기본은 액상(테스트 데이터 마이그레이션 정책과 일치).
  final FormulaForm form;
  /// 1통 양. 가루=g, 액상=ml. 단일 컬럼 재사용.
  final int containerGrams;
  /// 가루: 1g당 만들어지는 ml (= mlPerScoop / gPerScoop). 액상: 1.0 고정.
  final double mlPerGram;
  /// 가루분유 1스쿱 무게(g). 액상에서는 의미 없음.
  final double gPerScoop;
  /// 가루분유 1스쿱이 만드는 ml. 액상에서는 의미 없음.
  final double mlPerScoop;
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
  bool get isPowder => form == FormulaForm.powder;
  bool get isLiquid => form == FormulaForm.liquid;

  /// 통의 총 ml 환산값(추정). 액상은 containerGrams 그대로, 가루는 변환.
  double get totalMl => isLiquid
      ? containerGrams.toDouble()
      : containerGrams * mlPerGram;

  factory FormulaInventory.fromMap(Map<String, dynamic> map) {
    return FormulaInventory(
      id: map['id'] as String,
      childId: map['child_id'] as String,
      productName: map['product_name'] as String,
      brand: map['brand'] as String?,
      form: FormulaForm.fromString(map['form'] as String?),
      containerGrams: map['container_grams'] as int,
      mlPerGram: (map['ml_per_gram'] as num).toDouble(),
      gPerScoop: (map['g_per_scoop'] as num?)?.toDouble() ?? 4.4,
      mlPerScoop: (map['ml_per_scoop'] as num?)?.toDouble() ?? 30.0,
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
      'form': form.value,
      'container_grams': containerGrams,
      'ml_per_gram': mlPerGram,
      'g_per_scoop': gPerScoop,
      'ml_per_scoop': mlPerScoop,
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


/// 분유 통의 잔량/소비/소진 예상 통계 (계산 결과).
///
/// ── 계산 기준 ────────────────────────────────────────────────────────
/// - consumedG = sum(linked feedings.amount_ml) / mlPerGram
/// - remainingG = max(containerGrams - consumedG, 0)
/// - daysOpened = today - opened_at (정수 일수)
/// - dailyAvgG = consumedG / max(daysOpened, 1)
/// - expectedDaysLeft = remainingG / max(dailyAvgG, 0.1)
/// - confidence: opened_at 7일 이전이면 'low', 그 외 'normal'
class FormulaInventoryStats {
  const FormulaInventoryStats({
    required this.inventory,
    required this.consumedG,
    required this.dailyAvgG,
    required this.expectedDaysLeft,
    required this.confidence,
  });

  final FormulaInventory inventory;
  final double consumedG;
  final double dailyAvgG;
  final double expectedDaysLeft;
  /// 'low' = 개봉 후 7일 이내(샘플 적음), 'normal' = 그 외
  final String confidence;

  /// 잔량 (가루: g / 액상: ml — `inventory.form` 따라 해석. 음수 방지).
  double get remainingG {
    final r = inventory.containerGrams - consumedG;
    return r < 0 ? 0 : r;
  }

  /// 잔량 비율 (0.0 ~ 1.0). 진행률 표시용.
  double get remainingRatio {
    if (inventory.containerGrams == 0) return 0;
    return (remainingG / inventory.containerGrams).clamp(0.0, 1.0);
  }

  /// UI 표시용 잔량 라벨. 가루="320g", 액상="1,200ml".
  String get remainingDisplay {
    final n = remainingG.round();
    return inventory.isPowder ? '${n}g' : '${n}ml';
  }
}

