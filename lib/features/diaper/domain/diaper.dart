/// 기저귀 교체 기록 한 건 (diapers 테이블).
///
/// ── 색상의 의학적 의미 ───────────────────────────────────────────────
/// 노랑/갈색/녹색은 정상. 빨강/검정/흰색은 이상 신호 → 의사 상담 권장.
/// (빨강 = 혈변, 검정 = 소화관 출혈 가능, 흰색 = 담관 폐쇄 가능)
/// 이 의학 정보는 일반적 가이드일 뿐이고 진단은 의사가 함.
class Diaper {
  const Diaper({
    required this.id,
    required this.childId,
    required this.recordedAt,
    required this.type,
    this.color,
    this.consistency,
    this.amount,
    this.note,
    this.recordedBy,
    this.createdAt,
  });

  final String id;
  final String childId;
  final DateTime recordedAt;
  final String type;        // 'pee' | 'poop' | 'both'
  final String? color;      // 'yellow'|'brown'|'green'|'black'|'red'|'white'|'unknown'
  final String? consistency; // 'loose'|'normal'|'firm' (형태/질감)
  final String? amount;      // 'small'|'normal'|'large' (분량 — 조금/보통/많음)
  final String? note;
  final String? recordedBy;
  final DateTime? createdAt;

  /// 의사 상담 권장하는 이상 색상인가.
  bool get isAbnormalColor =>
      color == 'red' || color == 'black' || color == 'white';

  factory Diaper.fromMap(Map<String, dynamic> map) {
    return Diaper(
      id: map['id'] as String,
      childId: map['child_id'] as String,
      recordedAt: DateTime.parse(map['recorded_at'] as String),
      type: map['type'] as String,
      color: map['color'] as String?,
      consistency: map['consistency'] as String?,
      amount: map['amount'] as String?,
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
      'recorded_at': recordedAt.toUtc().toIso8601String(),
      'type': type,
      if (color != null) 'color': color,
      if (consistency != null) 'consistency': consistency,
      if (amount != null) 'amount': amount,
      if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
    };
  }
}
