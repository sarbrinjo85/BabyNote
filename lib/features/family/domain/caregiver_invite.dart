/// 부부/가족 공유 초대 코드 (caregiver_invites 테이블).
class CaregiverInvite {
  const CaregiverInvite({
    required this.id,
    required this.childId,
    required this.code,
    required this.role,
    required this.expiresAt,
    this.usedAt,
    required this.createdAt,
  });

  final String id;
  final String childId;
  final String code;
  final String role;
  final DateTime expiresAt;
  final DateTime? usedAt;
  final DateTime createdAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isUsed => usedAt != null;
  bool get isActive => !isExpired && !isUsed;

  factory CaregiverInvite.fromMap(Map<String, dynamic> map) {
    return CaregiverInvite(
      id: map['id'] as String,
      childId: map['child_id'] as String,
      code: map['code'] as String,
      role: map['role'] as String? ?? 'parent',
      expiresAt: DateTime.parse(map['expires_at'] as String),
      usedAt: map['used_at'] != null
          ? DateTime.parse(map['used_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
