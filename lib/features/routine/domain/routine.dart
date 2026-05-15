/// 일상 루틴 기록 한 건 (routines 테이블의 한 row).
///
/// ── 4종 통합 ─────────────────────────────────────────────────────────
/// kind 값에 따라 의미 있는 필드가 달라짐:
///   - walk(산책)       : durationMin 의미 있음, itemName null
///   - bath(목욕)       : durationMin 의미 있음, itemName null
///   - supplement(영양제): itemName 의미 있음 (예: "비타민D"), durationMin null
///   - snack(간식)      : itemName 의미 있음 (예: "사과 1/4쪽"), durationMin null
///
/// 4개 따로 테이블/모델을 만들지 않은 이유는 16_routines.sql 헤더 참고.
enum RoutineKind {
  walk,
  bath,
  supplement,
  snack;

  /// DB 컬럼 값과 1:1 매핑 ('walk' | 'bath' | 'supplement' | 'snack').
  String get dbValue => name;

  static RoutineKind fromDbValue(String v) {
    return RoutineKind.values.firstWhere(
      (k) => k.dbValue == v,
      orElse: () => throw ArgumentError('Unknown routine kind: $v'),
    );
  }

  /// 지속 시간을 입력받는 종류인가? (산책/목욕)
  bool get usesDuration => this == RoutineKind.walk || this == RoutineKind.bath;

  /// 이름(item)을 입력받는 종류인가? (영양제/간식)
  bool get usesItemName =>
      this == RoutineKind.supplement || this == RoutineKind.snack;

  /// UI 이모지 (홈 그리드/입력 화면 공통).
  String get emoji {
    switch (this) {
      case RoutineKind.walk:
        return '🚶';
      case RoutineKind.bath:
        return '🛁';
      case RoutineKind.supplement:
        return '💊';
      case RoutineKind.snack:
        return '🍪';
    }
  }
}

class Routine {
  const Routine({
    required this.id,
    required this.childId,
    required this.kind,
    required this.startedAt,
    this.durationMin,
    this.itemName,
    this.note,
    this.recordedBy,
    this.createdAt,
  });

  final String id;
  final String childId;
  final RoutineKind kind;
  final DateTime startedAt;

  /// 산책/목욕: 분 단위 지속 시간. 영양제/간식: null.
  final int? durationMin;

  /// 영양제/간식: 이름. 산책/목욕: null.
  final String? itemName;

  final String? note;
  final String? recordedBy;
  final DateTime? createdAt;

  factory Routine.fromMap(Map<String, dynamic> map) {
    return Routine(
      id: map['id'] as String,
      childId: map['child_id'] as String,
      kind: RoutineKind.fromDbValue(map['kind'] as String),
      startedAt: DateTime.parse(map['started_at'] as String),
      durationMin: map['duration_min'] as int?,
      itemName: map['item_name'] as String?,
      note: map['note'] as String?,
      recordedBy: map['recorded_by'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  /// INSERT payload — id 가 'pending' 이 아니면 포함 (오프라인 큐 용).
  /// createdAt/updatedAt 은 서버 default 가 채움.
  Map<String, dynamic> toInsertMap({required String recordedBy}) {
    return {
      // id 가 클라이언트에서 미리 정해진 경우(오프라인 큐) DB 에 그대로 넘김.
      // 'pending' sentinel 이면 서버 gen_random_uuid() 가 채움.
      if (id != 'pending') 'id': id,
      'child_id': childId,
      'recorded_by': recordedBy,
      'kind': kind.dbValue,
      'started_at': startedAt.toUtc().toIso8601String(),
      if (kind.usesDuration && durationMin != null) 'duration_min': durationMin,
      if (kind.usesItemName &&
          itemName != null &&
          itemName!.trim().isNotEmpty)
        'item_name': itemName!.trim(),
      if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
    };
  }

  /// UPDATE payload — kind/childId는 변경 불가 (kind가 바뀌면 새 기록으로 취급).
  Map<String, dynamic> toUpdateMap() {
    return {
      'started_at': startedAt.toUtc().toIso8601String(),
      'duration_min': kind.usesDuration ? durationMin : null,
      'item_name': kind.usesItemName
          ? (itemName?.trim().isEmpty ?? true ? null : itemName!.trim())
          : null,
      'note': (note?.trim().isEmpty ?? true) ? null : note!.trim(),
    };
  }
}
