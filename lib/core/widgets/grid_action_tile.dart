import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// 홈 화면 그리드 아이콘 타일 — 큰 이모지 + 라벨, 정사각형.
///
/// ── 디자인 결정 ──────────────────────────────────────────────────────
/// 4 column 그리드에 들어가는 정사각 타일. 새벽에도 한 손으로 누르도록 충분히 크게:
/// - 이모지 32sp (최대한 또렷)
/// - 라벨 12sp (보조 정보, 굵게)
/// - 카드 안에 InkWell — 탭 ripple
class GridActionTile extends StatelessWidget {
  const GridActionTile({
    super.key,
    required this.emoji,
    required this.label,
    required this.onTap,
    this.urgent = false,
  });

  final String emoji;
  final String label;
  final VoidCallback onTap;
  /// urgent=true면 errorContainer 색으로 강조 (분유 곧 소진 등).
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: urgent ? theme.colorScheme.errorContainer : null,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.brMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 11,
                  color: urgent
                      ? theme.colorScheme.onErrorContainer
                      : theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
