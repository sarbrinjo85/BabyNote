/// 단골 병원 한 곳 (hospitals 테이블).
///
/// ── RLS 약속 ─────────────────────────────────────────────────────────
/// hospitals는 user_id 기준이라 자녀가 아닌 사용자 본인 소유.
/// 부부가 같은 자녀 케어해도 단골 병원은 각자 다를 수 있음 (기획서 §4.3).
class Hospital {
  const Hospital({
    required this.id,
    required this.userId,
    required this.name,
    this.specialty,
    this.phone,
    this.address,
    this.latitude,
    this.longitude,
    this.note,
    this.isDefault = false,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  /// 'pediatrics' | 'dental' | 'er' | 'other'
  final String? specialty;
  final String? phone;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? note;
  final bool isDefault;
  final DateTime? createdAt;

  bool get hasCoordinates => latitude != null && longitude != null;

  factory Hospital.fromMap(Map<String, dynamic> map) {
    return Hospital(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      specialty: map['specialty'] as String?,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      note: map['note'] as String?,
      isDefault: (map['is_default'] as bool?) ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertMap({required String userId}) {
    return {
      'user_id': userId,
      'name': name,
      if (specialty != null) 'specialty': specialty,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      if (address != null && address!.isNotEmpty) 'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
      'is_default': isDefault,
    };
  }
}
