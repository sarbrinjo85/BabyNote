import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  /// 라이트 테마. primary=코랄, secondary/tertiary=민트, 배경=Coral Cream.
  static ThemeData light() =>
      _build(_buildScheme(Brightness.light), brightness: Brightness.light);

  /// 다크 테마. 새벽 모드에 그대로 사용 (시스템 다크 모드 따라감).
  static ThemeData dark() =>
      _build(_buildScheme(Brightness.dark), brightness: Brightness.dark);

  /// 두 시드(코랄 + 민트)에서 각각 ColorScheme 생성 후 합성.
  ///
  /// Flutter 3.41 시점에는 `ColorScheme.fromSeed`가 단일 시드만 받음
  /// (3.27+의 secondarySeed/tertiarySeed 인자 미지원). 그래서:
  ///   1) 코랄 seed로 base scheme 생성
  ///   2) 민트 seed로 별도 scheme 생성 (그쪽 primary 등을 추출)
  ///   3) base.copyWith로 secondary/tertiary 묶음을 민트로 교체
  ///
  /// 결과적으로 primary(코랄) × tertiary(민트) 듀얼 톤 완성.
  static ColorScheme _buildScheme(Brightness brightness) {
    final base = ColorScheme.fromSeed(
      seedColor: BrandColors.seed,
      brightness: brightness,
    );
    final mint = ColorScheme.fromSeed(
      seedColor: BrandColors.tertiarySeed,
      brightness: brightness,
    );
    return base.copyWith(
      // secondary/tertiary 둘 다 민트 — 의료/성장 영역에서 일관된 색
      secondary: mint.primary,
      onSecondary: mint.onPrimary,
      secondaryContainer: mint.primaryContainer,
      onSecondaryContainer: mint.onPrimaryContainer,
      tertiary: mint.primary,
      onTertiary: mint.onPrimary,
      tertiaryContainer: mint.primaryContainer,
      onTertiaryContainer: mint.onPrimaryContainer,
    );
  }

  /// 라이트/다크 공통 빌더.
  ///
  /// ColorScheme만 다르고 typography/component theme은 동일 → 두 테마가 일관됨.
  static ThemeData _build(ColorScheme cs,
      {required Brightness brightness}) {
    // 라이트 테마 한정으로 Coral Cream 통일 배경 적용.
    final isLight = brightness == Brightness.light;
    final scaffoldBg = isLight ? BrandColors.scaffoldLight : null;
    // 메뉴/버튼 누름 피드백 — 어두운 코랄
    const pressedDark = Color(0xFFD97A6C); // Coral Deep
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: scaffoldBg,
      canvasColor: scaffoldBg,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      // ripple(잔물결) 색
      splashColor: pressedDark.withValues(alpha: 0.28),
      // 누름 유지 시의 하이라이트 색 (탭 영역 전체)
      highlightColor: pressedDark.withValues(alpha: 0.16),

      // ── Typography: 둥근 느낌의 Jua(주아체) 적용 + 본문 1단계 키움 ──
      // Google Fonts의 Jua는 한국어 라운드 디스플레이 폰트.
      // 영문 글리프도 둥근 느낌. 사이즈/굵기는 그대로 유지.
      textTheme: GoogleFonts.juaTextTheme(
        const TextTheme(
          bodyLarge:  TextStyle(fontSize: 18, height: 1.4),
          bodyMedium: TextStyle(fontSize: 16, height: 1.4),
          bodySmall:  TextStyle(fontSize: 14, height: 1.35),
          labelLarge:  TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          titleLarge:  TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.3),
          titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3),
          titleSmall:  TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3),
          headlineLarge:  TextStyle(fontSize: 36, fontWeight: FontWeight.w700, height: 1.2),
          headlineMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.2),
          headlineSmall:  TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.2),
        ),
      ),

      // ── 버튼: 홈 메뉴 카드와 동일한 톤 ──────────────────────────────
      // 홈 GridActionTile = surfaceContainerLow 배경 + 코랄핑크 60% 테두리
      // FilledButton/OutlinedButton 모두 같은 시각 언어로 통일.
      // (특정 버튼이 styleFrom backgroundColor 으로 오버라이드 시 그쪽 우선)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.surfaceContainerLow,
          foregroundColor: const Color(0xFFD97A6C), // Coral Deep
          side: BorderSide(
            color: BrandColors.seed.withValues(alpha: 0.6),
            width: 1.2,
          ),
          minimumSize: const Size.fromHeight(TouchTarget.comfortable),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: cs.surfaceContainerLow,
          foregroundColor: const Color(0xFFD97A6C),
          side: BorderSide(
            color: BrandColors.seed.withValues(alpha: 0.6),
            width: 1.2,
          ),
          minimumSize: const Size.fromHeight(TouchTarget.comfortable),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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

      // ── AppBar: 라이트는 Coral Cream과 통일, 다크는 surface ─────────
      // titleTextStyle도 Jua로 통일 — appBar는 textTheme을 자동 적용하지 않으므로
      // GoogleFonts.jua(...)로 직접 감쌈.
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg ?? cs.surface,
        foregroundColor: cs.onSurface,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: GoogleFonts.jua(
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
