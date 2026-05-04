import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// 새벽에도 한 손으로 누를 수 있게 설계된 큰 액션 버튼.
///
/// 홈 화면의 4개 메인 기록(수유/수면/기저귀/성장)에 사용.
///
/// ── 디자인 의도 ──────────────────────────────────────────────────────
/// - **96dp 고정 높이** (TouchTarget.huge) → 졸린 눈으로도 누르기 쉬움
/// - **이모지/아이콘 큼지막** → 라벨 안 읽어도 의미 인식
/// - **글씨도 1단계 큼** → 어두운 환경에서 가독성
/// - **카드 형태 + 색상 표시** → 눌리는 영역 명확
class BigActionButton extends StatelessWidget {
  const BigActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.background,
    this.foreground,
  });

  /// 버튼에 표시할 텍스트 (예: "수유", "수면").
  final String label;

  /// 큰 아이콘 (Material Icons 또는 이모지를 IconData로 못 쓰니 Icon 위젯 자체를 받음).
  final Widget icon;

  /// 탭 콜백. null이면 비활성.
  final VoidCallback? onPressed;

  /// 배경색 (없으면 ColorScheme.primaryContainer 사용).
  final Color? background;

  /// 전경색 (텍스트/아이콘. 없으면 ColorScheme.onPrimaryContainer).
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = background ?? cs.primaryContainer;
    final fg = foreground ?? cs.onPrimaryContainer;

    return Material(
      color: bg,
      shape: const RoundedRectangleBorder(borderRadius: Radii.brLg),
      child: InkWell(
        onTap: onPressed,
        borderRadius: Radii.brLg,
        child: SizedBox(
          height: TouchTarget.huge,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            child: Row(
              children: [
                IconTheme(
                  data: IconThemeData(color: fg, size: 32),
                  child: icon,
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: fg.withValues(alpha: 0.6)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
