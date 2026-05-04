import 'package:flutter/material.dart';

import 'tokens.dart';

/// 앱 전체에 적용되는 Material 3 테마.
///
/// ── 베이비노트 테마 핵심 결정 ───────────────────────────────────────
/// 1. **새벽 한 손 사용 → 본문 글씨 1단계 키움** (16sp가 기본, 표준 14sp보다 큼)
/// 2. **버튼은 캡슐 모양** (한 손 엄지로 정확히 닿게 + 부드러운 인상)
/// 3. **라이트/다크 모두 따뜻한 톤** (병원 화이트 느낌 회피)
/// 4. **에러/경고 컬러는 ColorScheme.error 사용** (Material 3 표준)
class AppTheme {
  const AppTheme._();

  /// 라이트 테마.
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: BrandColors.seed,
      brightness: Brightness.light,
    );
    return _build(colorScheme);
  }

  /// 다크 테마. 새벽 모드에 그대로 사용 (시스템 다크 모드 따라감).
  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: BrandColors.seed,
      brightness: Brightness.dark,
    );
    return _build(colorScheme);
  }

  /// 라이트/다크 공통 빌더.
  ///
  /// ColorScheme만 다르고 typography/component theme은 동일 → 두 테마가 일관됨.
  static ThemeData _build(ColorScheme cs) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // ── Typography: 본문 1단계 키움 ─────────────────────────────────
      // Material 3 default(bodyLarge=16, bodyMedium=14)에서 한 단계 위로 시프트.
      // 라벨/제목은 비례적으로 따라 키움.
      textTheme: const TextTheme(
        // 본문 — 가장 흔히 쓰임
        bodyLarge:  TextStyle(fontSize: 18, height: 1.4),
        bodyMedium: TextStyle(fontSize: 16, height: 1.4),
        bodySmall:  TextStyle(fontSize: 14, height: 1.35),

        // 라벨 — 버튼 텍스트, 칩 등
        labelLarge:  TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),

        // 제목 — Card 헤더, AppBar 등
        titleLarge:  TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.3),
        titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3),
        titleSmall:  TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3),

        // 큰 디스플레이 (Hero, 환영 메시지)
        headlineLarge:  TextStyle(fontSize: 36, fontWeight: FontWeight.w700, height: 1.2),
        headlineMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.2),
        headlineSmall:  TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.2),
      ),

      // ── 버튼: 캡슐 모양 + 큰 터치 타겟 ──────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(TouchTarget.comfortable),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(TouchTarget.comfortable),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, TouchTarget.standard),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // ── 입력 필드: 둥글고 약간 큰 패딩 ──────────────────────────────
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: Radii.brMd),
        contentPadding:
            EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
      ),

      // ── Card: 모서리 둥글게, elevation 낮게 (Material 3 권장) ───────
      cardTheme: CardThemeData(
        margin: const EdgeInsets.symmetric(vertical: Spacing.xs),
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: Radii.brMd),
        color: cs.surfaceContainerLow,
      ),

      // ── AppBar: 배경 = surface, 그림자 없음 (M3 기본) ───────────────
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      ),

      // ── SnackBar: 둥글게 + 살짝 떠있게 ──────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: Radii.brMd),
        contentTextStyle: TextStyle(fontSize: 16, color: cs.onInverseSurface),
      ),
    );
  }
}
