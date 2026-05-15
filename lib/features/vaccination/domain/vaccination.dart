/// 자녀의 예방접종 기록 한 건 (vaccinations 테이블).
///
/// ── 마스터(vaccine_schedules)와의 관계 ───────────────────────────────
/// vaccineScheduleId로 마스터 row를 가리킴. NULL이면 출장백신 등 임의 접종.
/// vaccineCode + doseNumber는 denormalized — 마스터가 사라져도 무엇을 맞았는지
/// 알 수 있게.
///
/// ── 상태 ─────────────────────────────────────────────────────────────
/// - administeredAt 채워짐 → 완료
/// - administeredAt NULL이고 scheduledFor 있음 → 예약됨
/// - 둘 다 NULL → 단순 의도 등록 (드물게 사용)
class Vaccination {
  const Vaccination({
    required this.id,
    required this.childId,
    required this.vaccineCode,
    required this.doseNumber,
    this.vaccineScheduleId,
    this.scheduledFor,
    this.administeredAt,
    this.hospitalId,
    this.note,
    this.recordedBy,
    this.createdAt,
  });

  final String id;
  final String childId;
  final String? vaccineScheduleId;
  final String vaccineCode;
  final int doseNumber;
  final DateTime? scheduledFor;
  final DateTime? administeredAt;
  final String? hospitalId;
  final String? note;
  final String? recordedBy;
  final DateTime? createdAt;

  bool get isCompleted => administeredAt != null;

  factory Vaccination.fromMap(Map<String, dynamic> map) {
    return Vaccination(
      id: map['id'] as String,
      childId: map['child_id'] as String,
      vaccineScheduleId: map['vaccine_schedule_id'] as String?,
      vaccineCode: map['vaccine_code'] as String,
      doseNumber: map['dose_number'] as int,
      scheduledFor: map['scheduled_for'] != null
          ? DateTime.parse(map['scheduled_for'] as String)
          : null,
      administeredAt: map['administered_at'] != null
          ? DateTime.parse(map['administered_at'] as String)
          : null,
      hospitalId: map['hospital_id'] as String?,
      note: map['note'] as String?,
      recordedBy: map['recorded_by'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertMap({required String recordedBy}) {
    return {
      if (id != 'pending') 'id': id,
      'child_id': childId,
      'recorded_by': recordedBy,
      'vaccine_code': vaccineCode,
      'dose_number': doseNumber,
      if (vaccineScheduleId != null) 'vaccine_schedule_id': vaccineScheduleId,
      if (scheduledFor != null) 'scheduled_for': _date(scheduledFor!),
      if (administeredAt != null)
        'administered_at': administeredAt!.toUtc().toIso8601String(),
      if (hospitalId != null) 'hospital_id': hospitalId,
      if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
    };
  }

  static String _date(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }
}
