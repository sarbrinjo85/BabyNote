/// 수면 기록 한 건 (sleeps 테이블의 한 row).
///
/// ── 진행 중 수면 ─────────────────────────────────────────────────────
/// `endedAt`이 null이면 아직 깨지 않은 상태. UI는 "OOO 자녀가 자고 있어요"
/// 같은 진행 중 카드로 표시. 한 자녀당 동시에 진행 중 수면은 1건이라고 가정.
///
/// ── 낮잠/밤잠 ────────────────────────────────────────────────────────
/// 19~07시 시작은 'night', 그 외는 'nap'으로 자동 판정 (사용자 수정 가능).
/// 한국·일본·미국 부모 모두에게 통하는 단순 규칙.
class Sleep {
  const Sleep({
    required this.id,
    required this.childId,
    required this.startedAt,
    required this.napOrNight,
    this.endedAt,
    this.note,
    this.recordedBy,
    this.createdAt,
  });

  final String id;
  final String childId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String napOrNight; // 'nap' | 'night'
  final String? note;
  final String? recordedBy;
  final DateTime? createdAt;

  /// 진행 중 수면? (= endedAt이 null)
  bool get isOngoing => endedAt == null;

  /// 경과 시간(분). 진행 중이면 now 기준, 종료되었으면 startedAt~endedAt 기준.
  int elapsedMinutes(DateTime now) {
    final end = endedAt ?? now;
    return end.difference(startedAt).inMinutes;
  }

  factory Sleep.fromMap(Map<String, dynamic> map) {
    return Sleep(
      id: map['id'] as String,
      childId: map['child_id'] as String,
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: map['ended_at'] != null
          ? DateTime.parse(map['ended_at'] as String)
          : null,
      napOrNight: map['nap_or_night'] as String,
      note: map['note'] as String?,
      recordedBy: map['recorded_by'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  /// 시작 INSERT용 payload — endedAt은 보내지 않음 (NULL = 진행 중).
  /// id 가 'pending' 이 아니면 포함 (오프라인 큐 — 클라이언트 측 UUID).
  Map<String, dynamic> toStartInsertMap({required String recordedBy}) {
    return {
      if (id != 'pending') 'id': id,
      'child_id': childId,
      'recorded_by': recordedBy,
      'started_at': startedAt.toUtc().toIso8601String(),
      'nap_or_night': napOrNight,
      if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
    };
  }

  /// 19~07시면 night, 그 외는 nap.
  static String classifyNapOrNight(DateTime t) {
    final h = t.hour;
    return (h >= 19 || h < 7) ? 'night' : 'nap';
  }
}
