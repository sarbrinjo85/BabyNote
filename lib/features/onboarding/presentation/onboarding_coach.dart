import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

/// 최초 앱 실행 시 1회 표시되는 홈 화면 코치 마크.
///
/// ── 동작 ─────────────────────────────────────────────────────────────
/// - postFrame 콜백에서 `OnboardingCoach.maybeShow(context)` 호출
/// - SharedPreferences `seen_home_onboarding` 플래그가 false면 dimmed 배경 +
///   화살표 + 설명을 가진 fullscreen overlay 표시
/// - 사용자가 끝까지 보거나 스킵하면 플래그를 true로 저장 → 다음부터 안 뜸
///
/// ── 키 사용 ──────────────────────────────────────────────────────────
/// 하이라이트할 위젯에 `OnboardingCoach.recordsGridKey` 같은 GlobalKey를 부착.
/// 위젯 트리에 mount되어 있어야 위치 계산이 가능.
class OnboardingCoach {
  OnboardingCoach._();

  static const _prefKey = 'seen_home_onboarding';

  /// 현재 앱 세션에서 한 번이라도 닫힌 적 있으면 더 이상 자동 표시 X.
  /// 앱 재시작하면 false로 초기화 → seen=false라면 다시 표시.
  static bool _dismissedThisSession = false;

  // 하이라이트 대상 GlobalKey들 — 홈 화면에서 부착.
  static final addChildKey = GlobalKey();
  static final bellKey = GlobalKey();
  static final recordButtonsKey = GlobalKey();
  static final dataMenuKey = GlobalKey();
  static final medicalMenuKey = GlobalKey();
  static final fabKey = GlobalKey();

  static Future<bool> hasSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
  }

  /// 다음 앱 재실행 시 코치 마크가 다시 보이도록 — seen 플래그 해제.
  /// 현재 세션에서는 이미 본 것으로 처리(_dismissedThisSession=true)되어
  /// 즉시 재표시되지 않음.
  static Future<void> markUnseenForNextLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    _dismissedThisSession = true;
  }

  static Future<void> resetForTest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    _dismissedThisSession = false;
  }

  /// 첫 실행이면 코치 마크 시작.
  /// 현재 세션에서 이미 한 번 닫혔다면(_dismissedThisSession) 표시 안 함.
  static Future<void> maybeShow(BuildContext context) async {
    if (_dismissedThisSession) return;
    if (await hasSeen()) return;
    if (!context.mounted) return;
    show(context);
  }

  /// 강제로 코치 마크 보여주기 (설정 → "도움말 다시 보기" 등).
  static void show(BuildContext context) {
    final theme = Theme.of(context);

    /// [extraOffset] — 텍스트와 포커스 사이 여백 (px). align.top일 때는 위로
    /// 더 올리기 위해 builder 외곽에 SizedBox를 더해 자연스럽게 분리.
    TargetContent textContent(
      String title,
      String body,
      ContentAlign align, {
      double extraOffset = 0,
    }) {
      return TargetContent(
        align: align,
        builder: (ctx, ctrl) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (align == ContentAlign.bottom && extraOffset > 0)
                SizedBox(height: extraOffset),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
                  height: 1.5,
                ),
              ),
              if (align == ContentAlign.top && extraOffset > 0)
                SizedBox(height: extraOffset),
            ],
          ),
        ),
      );
    }

    final targets = <TargetFocus>[
      if (OnboardingCoach.addChildKey.currentContext != null)
        TargetFocus(
          identify: 'add_child',
          keyTarget: OnboardingCoach.addChildKey,
          contents: [
            textContent('자녀 추가',
                '여기에서 새로운 자녀를 등록할 수 있어요.\n생년월일과 성별만 있으면 시작!',
                ContentAlign.bottom),
          ],
          shape: ShapeLightFocus.Circle,
          radius: 8,
        ),
      if (OnboardingCoach.bellKey.currentContext != null)
        TargetFocus(
          identify: 'bell',
          keyTarget: OnboardingCoach.bellKey,
          contents: [
            textContent('알림 종', '다가오는 예방접종이나 분유 부족 같은\n중요 일정을 한눈에 모아 보여드려요.',
                ContentAlign.bottom),
          ],
          shape: ShapeLightFocus.Circle,
        ),
      if (OnboardingCoach.recordButtonsKey.currentContext != null)
        TargetFocus(
          identify: 'records',
          keyTarget: OnboardingCoach.recordButtonsKey,
          paddingFocus: 0,
          contents: [
            textContent('오늘의 기록',
                '수유, 수면, 기저귀, 성장 4가지를 한 탭으로 기록해요.\n각 버튼에 마지막 활동 시간이 함께 표시돼요.',
                ContentAlign.top, extraOffset: 140),
          ],
          radius: 14,
        ),
      if (OnboardingCoach.dataMenuKey.currentContext != null)
        TargetFocus(
          identify: 'data_menu',
          keyTarget: OnboardingCoach.dataMenuKey,
          paddingFocus: 0,
          contents: [
            textContent('데이터/관리',
                '분유·기저귀 재고 관리, 기록 편집, 성장 통계로 진입해요.',
                ContentAlign.top, extraOffset: 140),
          ],
          radius: 14,
        ),
      if (OnboardingCoach.medicalMenuKey.currentContext != null)
        TargetFocus(
          identify: 'medical_menu',
          keyTarget: OnboardingCoach.medicalMenuKey,
          paddingFocus: 0,
          contents: [
            textContent('의료',
                '단골 병원 등록과 예방접종 일정을 한 곳에서 관리해요.',
                ContentAlign.top, extraOffset: 140),
          ],
          radius: 14,
        ),
      if (OnboardingCoach.fabKey.currentContext != null)
        TargetFocus(
          identify: 'fab',
          keyTarget: OnboardingCoach.fabKey,
          contents: [
            textContent('간편 수유 입력',
                '한 번 탭하면 마지막 수유와 같은 양으로 즉시 저장.\n길게 누르면 수유량을 직접 입력할 수 있어요.',
                ContentAlign.top),
          ],
          shape: ShapeLightFocus.RRect,
          radius: 30,
        ),
    ];

    if (targets.isEmpty) return;

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.85,
      paddingFocus: 6,
      hideSkip: false,
      textSkip: '다시 보지 않기',
      alignSkip: Alignment.topRight,
      textStyleSkip: TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      onSkip: () {
        // "다시 보지 않기" — seen=true 영구 저장 + 세션 dismissed 표시
        markSeen();
        _dismissedThisSession = true;
        return true;
      },
      onFinish: () {
        markSeen();
        _dismissedThisSession = true;
      },
      pulseEnable: true,
      focusAnimationDuration: const Duration(milliseconds: 350),
      pulseAnimationDuration: const Duration(milliseconds: 800),
      // 화살표는 builder 안에서 텍스트 위치(align)로 자연스러운 방향 표시.
      imageFilter: null,
    ).show(context: context);
  }
}
