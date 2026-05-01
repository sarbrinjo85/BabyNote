/// 국가별 표준 예방접종 일정 한 건 (vaccine_schedules 테이블의 한 row).
///
/// ── 도메인 모델이란 ─────────────────────────────────────────────────
/// "DB row를 그대로 들고 다니지 말고, 앱이 다루는 형태(불변 객체)로 변환해서 쓰자"가
/// Clean Architecture의 핵심. data 레이어(Supabase `Map<String, dynamic>`)와
/// presentation 레이어(Widget)가 이 클래스를 통해서만 대화하면, DB 컬럼명이 바뀌어도
/// UI가 영향받지 않음 (변환 로직만 고치면 됨).
///
/// ── 왜 final + const 생성자 ───────────────────────────────────────────
/// 모든 필드 final + 생성자에 const → "불변 객체(immutable)". 한 번 만들면 못 바꿈.
/// Riverpod이 상태 비교할 때 == 연산을 안전하게 쓸 수 있고, 동시성 버그를 원천 차단.
///
/// ── recommendedAgeDays ────────────────────────────────────────────────
/// 생후 며칠에 권장되는지(int). 예: 28 = 생후 4주, 365 = 12개월.
/// "생후 X일"을 "X개월"로 바꾸는 변환은 presentation 레이어 책임.
class VaccineSchedule {
  const VaccineSchedule({
    required this.id,
    required this.country,
    required this.code,
    required this.name,
    required this.doseNumber,
    required this.recommendedAgeDays,
    this.description,
  });

  final String id;
  final String country;
  final String code;
  final String name;
  final int doseNumber;
  final int recommendedAgeDays;
  final String? description; // nullable: DB 컬럼이 NULL일 수 있음

  /// Supabase가 돌려주는 raw map(`Map<String, dynamic>`)을 도메인 객체로 변환.
  ///
  /// `factory` 키워드는 "이 클래스 인스턴스를 만들어주지만 일반 생성자와 달리 로직을
  /// 한 번 거친 뒤 반환"한다는 뜻. fromXxx 패턴에 흔히 씀.
  ///
  /// `as String`, `as int` 같은 캐스팅은 잘못된 타입이 오면 즉시 예외 → 빠른 실패.
  /// 안전한 파싱이 필요하면 `int.parse(...)` / `int.tryParse(...)` 패턴으로 교체.
  factory VaccineSchedule.fromMap(Map<String, dynamic> map) {
    return VaccineSchedule(
      id: map['id'] as String,
      country: map['country'] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      doseNumber: map['dose_number'] as int,
      recommendedAgeDays: map['recommended_age_days'] as int,
      description: map['description'] as String?, // 끝에 ? = null 허용
    );
  }
}
