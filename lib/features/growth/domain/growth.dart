/// 성장 측정 한 건 (growths 테이블).
///
/// ── 단위 약속 ────────────────────────────────────────────────────────
/// DB는 항상 metric 정수:
///   - weightG  (g)   예: 8.45 kg → 8450
///   - heightMm (mm)  예: 75.5 cm → 755
///   - headCircumferenceMm (mm)
///
/// presentation 레이어가 사용자 입력(kg, cm)을 metric으로 변환해서 넘김.
class Growth {
  const Growth({
    required this.id,
    required this.childId,
    required this.measuredAt,
    this.weightG,
    this.heightMm,
    this.headCircumferenceMm,
    this.note,
    this.recordedBy,
    this.createdAt,
  });

  final String id;
  final String childId;
  final DateTime measuredAt;
  final int? weightG;
  final int? heightMm;
  final int? headCircumferenceMm;
  final String? note;
  final String? recordedBy;
  final DateTime? createdAt;

  factory Growth.fromMap(Map<String, dynamic> map) {
    return Growth(
      id: map['id'] as String,
      childId: map['child_id'] as String,
      measuredAt: DateTime.parse(map['measured_at'] as String),
      weightG: map['weight_g'] as int?,
      heightMm: map['height_mm'] as int?,
      headCircumferenceMm: map['head_circumference_mm'] as int?,
      note: map['note'] as String?,
      recordedBy: map['recorded_by'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertMap({required String recordedBy}) {
    return {
      'child_id': childId,
      'recorded_by': recordedBy,
      'measured_at': measuredAt.toUtc().toIso8601String(),
      if (weightG != null) 'weight_g': weightG,
      if (heightMm != null) 'height_mm': heightMm,
      if (headCircumferenceMm != null) 'head_circumference_mm': headCircumferenceMm,
      if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
    };
  }
}
