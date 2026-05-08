import 'package:flutter/material.dart';

/// 앱 전역 디자인 토큰.
///
/// ── 토큰이란 ─────────────────────────────────────────────────────────
/// "간격 8px"이라는 magic number가 코드 곳곳에 흩어지면 일관성 잡기 어려움.
/// `Spacing.md` 같은 이름으로 모아두면:
///   - 한 군데서 값 바꾸면 전 앱 반영
///   - 문맥 있는 이름 → 의미 전달
///   - 디자이너와 개발자가 같은 언어 사용
///
/// ── 베이비노트 컨셉 ────────────────────────────────────────────────
/// "새벽에도 한 손으로" → 표준보다 큰 버튼·큰 글씨·넉넉한 터치 영역.
/// 모바일 일반 권장(터치 타겟 48dp)보다 크게, 본문 글씨도 14sp 대신 16~18sp.

/// 간격 (margin/padding) 8pt grid 기반.
class Spacing {
  const Spacing._();

  /// 4 — 아이콘과 라벨 사이같은 매우 좁은 간격
  static const double xxs = 4;

  /// 8 — 컴포넌트 내부 작은 간격
  static const double xs = 8;

  /// 12
  static const double sm = 12;

  /// 16 — 카드/리스트 기본 패딩
  static const double md = 16;

  /// 24 — 섹션 간 분리
  static const double lg = 24;

  /// 32
  static const double xl = 32;

  /// 48 — 화면 큰 분리
  static const double xxl = 48;
}

/// 모서리 둥글기.
class Radii {
  const Radii._();

  static const Radius sm = Radius.circular(8);
  static const Radius md = Radius.circular(12);
  static const Radius lg = Radius.circular(20);
  static const Radius pill = Radius.circular(999); // 캡슐 모양 버튼

  static const BorderRadius brSm = BorderRadius.all(sm);
  static const BorderRadius brMd = BorderRadius.all(md);
  static const BorderRadius brLg = BorderRadius.all(lg);
  static const BorderRadius brPill = BorderRadius.all(pill);
}

/// 인터랙션 가능한 영역의 최소 크기 (터치 타겟).
class TouchTarget {
  const TouchTarget._();

  /// 48 — Material/iOS 모두의 표준 최소
  static const double standard = 48;

  /// 64 — 베이비노트 일반 버튼 (한 손 친화)
  static const double comfortable = 64;

  /// 96 — 4개 메인 기록 버튼 (수유/수면/기저귀/성장)용
  /// 새벽에 졸린 눈으로 흔들리는 손가락도 정확히 누를 수 있는 크기
  static const double huge = 96;
}

/// 시드 컬러 (Material 3 ColorScheme.fromSeed 입력).
///
/// ── 듀얼 시드 (출시용 브랜드 정체성) ──────────────────────────────
/// primary  = 코랄  (따뜻함 + 가족 + 사랑) — 일반 액션, 상태 카드
/// tertiary = 민트  (의료 신뢰 + 청량) — 접종/성장 차트 등 의료성 영역
/// 이 두 색의 대비로 베이비노트 핵심 가치(따뜻함 × 신뢰성) 동시 표현.
///
/// 한·일·미 사용자에게 모두 친숙한 중성적 톤 — 성별 편중 없음.
class BrandColors {
  const BrandColors._();

  /// 파스텔 코랄 핑크. ColorScheme.fromSeed의 primary seed.
  /// (이전 0xFFF0958F → 한 단계 더 부드럽게)
  static const Color seed = Color(0xFFFFB5A7);

  /// 파스텔 민트. tertiarySeed — 코랄과 무게 비슷하게 맞춤.
  static const Color tertiarySeed = Color(0xFFB6E3C9);

  /// 라이트 테마 전체 배경색 — 코랄핑크 hint가 살짝 들어간 밝은 톤.
  /// Scaffold/AppBar/Card 배경에 통일감 부여.
  static const Color scaffoldLight = Color(0xFFFFF5F0);
}

/// 애니메이션 지속 시간 (Material Motion 권장 기반).
class Durations {
  const Durations._();

  static const Duration short = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration long = Duration(milliseconds: 400);
}
