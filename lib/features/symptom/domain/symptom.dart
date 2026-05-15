/// 건강 증상 기록 (symptoms 테이블의 한 row).
///
/// ── 4종 통합 ─────────────────────────────────────────────────────────
/// kind 별 의미 있는 필드:
///   - cough (기침)  : severity, note. 사진은 보통 안 씀.
///   - vomit (구토)  : severity, note.
///   - rash  (발진)  : severity, note, photoPath (사진 첨부 권장)
///   - injury(상처)  : severity, note, photoPath (사진 첨부 권장)
///
/// ── severity 의미 ───────────────────────────────────────────────────
/// mild (가벼움) / moderate (보통) / severe (심함). null 도 허용 (입력 안 함).
enum SymptomKind {
  cough,
  vomit,
  rash,
  injury;

  String get dbValue => name;

  static SymptomKind fromDbValue(String v) {
    return SymptomKind.values.firstWhere(
      (k) => k.dbValue == v,
      orElse: () => throw ArgumentError('Unknown symptom kind: $v'),
    );
  }

  /// 사진 첨부가 자연스러운 종류 (발진/상처).
  bool get supportsPhoto =>
      this == SymptomKind.rash || this == SymptomKind.injury;

  String get emoji {
    switch (this) {
      case SymptomKind.cough:
        return '😷';
      case SymptomKind.vomit:
        return '🤢';
      case SymptomKind.rash:
        return '🌶️';
      case SymptomKind.injury:
        return '🩹';
    }
  }
}

/// 증상 강도. DB 컬럼 'severity' 값과 1:1.
enum Severity {
  mild,
  moderate,
  severe;

  String get dbValue => name;

  static Severity? fromDbValue(String? v) {
    if (v == null) return null;
    return Severity.values.firstWhere(
      (s) => s.dbValue == v,
      orElse: () => throw ArgumentError('Unknown severity: $v'),
    );
  }
}

class Symptom {
  const Symptom({
    required this.id,
    required this.childId,
    required this.kind,
    required this.occurredAt,
    this.severity,
    this.photoPath,
    this.note,
    this.recordedBy,
    this.createdAt,
  });

  final String id;
  final String childId;
  final SymptomKind kind;
  final DateTime occurredAt;
  final Severity? severity;

  /// Supabase Storage 'symptom-photos' 버킷 안의 path. null = 사진 없음.
  /// 표시 시 `supabase.storage.from('symptom-photos').getPublicUrl(photoPath)`.
  final String? photoPath;

  final String? note;
  final String? recordedBy;
  final DateTime? createdAt;

  factory Symptom.fromMap(Map<String, dynamic> map) {
    return Symptom(
      id: map['id'] as String,
      childId: map['child_id'] as String,
      kind: SymptomKind.fromDbValue(map['kind'] as String),
      occurredAt: DateTime.parse(map['occurred_at'] as String),
      severity: Severity.fromDbValue(map['severity'] as String?),
      photoPath: map['photo_path'] as String?,
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
      'kind': kind.dbValue,
      'occurred_at': occurredAt.toUtc().toIso8601String(),
      if (severity != null) 'severity': severity!.dbValue,
      if (photoPath != null) 'photo_path': photoPath,
      if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'occurred_at': occurredAt.toUtc().toIso8601String(),
      'severity': severity?.dbValue,
      'photo_path': photoPath,
      'note': (note?.trim().isEmpty ?? true) ? null : note!.trim(),
    };
  }
}
