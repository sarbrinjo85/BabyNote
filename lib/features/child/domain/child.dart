/// 자녀 한 명을 표현하는 불변 도메인 모델 (children 테이블의 한 row).
///
/// ── 단위 약속 (DB 스키마와 일치) ──────────────────────────────────────
/// - 무게 weight_g  : 정수, 그램 (g). 예: 3.45 kg → 3450
/// - 키   height_mm : 정수, 밀리미터 (mm). 예: 51.5 cm → 515
///
/// presentation 레이어가 사용자 입력(kg, cm)을 metric으로 변환해서 넘김.
/// 화면에 보여줄 땐 다시 kg/cm로 변환. DB는 항상 metric 정수로 통일.
class Child {
  const Child({
    required this.id,
    required this.name,
    required this.birthDate,
    this.gender,
    this.birthWeightG,
    this.birthHeightMm,
    this.isPaid = false,
    this.createdBy,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? gender;          // 'male' | 'female' | 'other' | null
  final DateTime birthDate;      // 생년월일 (date 컬럼이라 시간 정보 없음)
  final int? birthWeightG;       // 출생 시 무게 (g)
  final int? birthHeightMm;      // 출생 시 키 (mm)
  final bool isPaid;             // 둘째 자녀부터 유료 표시 (캐시)
  final String? createdBy;       // user_profiles.id (FK)
  final DateTime? createdAt;     // DB 생성 시각

  /// Supabase select 응답(`Map<String, dynamic>`) → Child 객체.
  factory Child.fromMap(Map<String, dynamic> map) {
    return Child(
      id: map['id'] as String,
      name: map['name'] as String,
      gender: map['gender'] as String?,
      // birth_date는 'YYYY-MM-DD' 문자열로 와서 DateTime으로 파싱.
      birthDate: DateTime.parse(map['birth_date'] as String),
      birthWeightG: map['birth_weight_g'] as int?,
      birthHeightMm: map['birth_height_mm'] as int?,
      isPaid: (map['is_paid'] as bool?) ?? false,
      createdBy: map['created_by'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  /// INSERT용 payload — id/created_at/created_by 같은 서버가 채울 컬럼은 제외.
  /// created_by는 children_set_created_by 트리거가 auth.uid()로 자동 채워줌
  /// (08_auto_created_by.sql 참조). 클라이언트는 보내지 않음 → token mismatch 회피.
  Map<String, dynamic> toInsertMap() {
    return {
      'name': name,
      if (gender != null) 'gender': gender,
      // date 컬럼: 'YYYY-MM-DD' 문자열로 보내야 안전 (timezone 영향 없음).
      'birth_date': _toDateString(birthDate),
      if (birthWeightG != null) 'birth_weight_g': birthWeightG,
      if (birthHeightMm != null) 'birth_height_mm': birthHeightMm,
    };
  }

  /// 생후 며칠인가. 화면에 "생후 87일" 같이 표시할 때 사용.
  int ageInDays(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final birth = DateTime(birthDate.year, birthDate.month, birthDate.day);
    return today.difference(birth).inDays;
  }

  /// 'YYYY-MM-DD' 형식으로 직렬화. intl 패키지 없이 직접 처리(의존성 최소화).
  static String _toDateString(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
