/// 자녀의 케어기버 한 명 (caregivers 테이블의 한 row).
///
/// ── role ────────────────────────────────────────────────────────────
/// 'parent' / 'grandparent' / 'nanny' / 'other'
/// 화면에서 라벨링용. 권한은 모두 동일 (RLS는 caregiver 여부만 본다).
class Caregiver {
  const Caregiver({
    required this.id,
    required this.childId,
    required this.userId,
    required this.role,
    this.acceptedAt,
    this.displayName,
    this.email,
  });

  final String id;
  final String childId;
  final String userId;
  final String role;
  final DateTime? acceptedAt;
  /// JOIN을 통해 user_profiles에서 가져옴 (선택).
  final String? displayName;
  /// auth.users 테이블의 email — JOIN으로 가져옴 (선택).
  final String? email;

  /// 본인이 본 caregiver 자신인지 — UI에서 "나" 표시.
  bool isSelf(String myUserId) => userId == myUserId;

  factory Caregiver.fromMap(Map<String, dynamic> map) {
    final profile = map['user_profile'] as Map<String, dynamic>?;
    return Caregiver(
      id: map['id'] as String,
      childId: map['child_id'] as String,
      userId: map['user_id'] as String,
      role: map['role'] as String? ?? 'parent',
      acceptedAt: map['accepted_at'] != null
          ? DateTime.parse(map['accepted_at'] as String)
          : null,
      displayName: profile?['display_name'] as String?,
      email: null, // auth.users JOIN은 RLS 때문에 직접 안 됨. display_name으로 대체.
    );
  }
}
