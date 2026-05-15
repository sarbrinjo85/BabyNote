/// 수유 기록 한 건 (feedings 테이블의 한 row).
///
/// ── 3가지 타입 ───────────────────────────────────────────────────────
/// - breast(모유)  : breastSide(left/right/both) + amountMl(선택)
/// - formula(분유) : amountMl(필수) + formulaBrand(선택)
/// - solid(이유식) : foodName(필수) + amountMl(선택, 의미 모호함)
///
/// ── 시각 약속 ────────────────────────────────────────────────────────
/// startedAt 필수 (DB도 not null). endedAt은 모유/분유는 보통 종료 시점,
/// 이유식은 같은 시각으로 기록하거나 NULL.
class Feeding {
  const Feeding({
    required this.id,
    required this.childId,
    required this.type,
    required this.startedAt,
    this.endedAt,
    this.amountMl,
    this.breastSide,
    this.foodName,
    this.formulaBrand,
    this.formulaInventoryId,
    this.note,
    this.photoPath,
    this.recordedBy,
    this.createdAt,
  });

  final String id;
  final String childId;
  final String type; // 'breast' | 'formula' | 'solid'
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? amountMl;
  final String? breastSide; // 'left' | 'right' | 'both'
  final String? foodName;
  final String? formulaBrand;
  /// FIFO로 자동 연결된 활성 분유 통 id. P3-1b부터 사용. NULL 가능.
  final String? formulaInventoryId;
  final String? note;
  /// Storage 경로 (예: `<user_id>/20260502_193512.jpg`).
  /// 실제 표시 URL은 supabase.storage.from('feeding-photos').getPublicUrl(photoPath).
  final String? photoPath;
  final String? recordedBy;
  final DateTime? createdAt;

  /// Supabase select 응답을 도메인 객체로 변환.
  factory Feeding.fromMap(Map<String, dynamic> map) {
    return Feeding(
      id: map['id'] as String,
      childId: map['child_id'] as String,
      type: map['type'] as String,
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: map['ended_at'] != null
          ? DateTime.parse(map['ended_at'] as String)
          : null,
      amountMl: map['amount_ml'] as int?,
      breastSide: map['breast_side'] as String?,
      foodName: map['food_name'] as String?,
      formulaBrand: map['formula_brand'] as String?,
      formulaInventoryId: map['formula_inventory_id'] as String?,
      note: map['note'] as String?,
      photoPath: map['photo_path'] as String?,
      recordedBy: map['recorded_by'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  /// INSERT용 payload — recorded_by/created_at 등 서버가 채울 컬럼은 제외.
  /// id 가 'pending' 이 아니면 포함 (오프라인 큐 — 클라이언트 측 UUID).
  /// recorded_by는 호출 측에서 currentUser.id를 따로 넘김.
  Map<String, dynamic> toInsertMap({required String recordedBy}) {
    return {
      if (id != 'pending') 'id': id,
      'child_id': childId,
      'recorded_by': recordedBy,
      'type': type,
      // timestamptz는 ISO 8601 UTC 문자열로 직렬화. toIso8601String()이 그 형식.
      'started_at': startedAt.toUtc().toIso8601String(),
      if (endedAt != null) 'ended_at': endedAt!.toUtc().toIso8601String(),
      if (amountMl != null) 'amount_ml': amountMl,
      if (breastSide != null) 'breast_side': breastSide,
      if (foodName != null) 'food_name': foodName,
      if (formulaBrand != null) 'formula_brand': formulaBrand,
      if (formulaInventoryId != null) 'formula_inventory_id': formulaInventoryId,
      if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
      if (photoPath != null) 'photo_path': photoPath,
    };
  }
}
