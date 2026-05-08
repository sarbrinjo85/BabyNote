import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'elephant_loader.dart';

/// 로딩 인디케이터 — Lottie 애니메이션이 있으면 그걸 사용, 없으면 fallback.
///
/// ── 사용 ─────────────────────────────────────────────────────────────
/// 기존 `BabyLoading()` 자리에 그대로 교체.
///   `Center(child: BabyLoading())`
///
/// ── Lottie 파일 추가 ────────────────────────────────────────────────
/// `assets/lottie/loading.json` 경로에 .json 파일을 두면 자동 사용.
/// 추천 검색: lottiefiles.com — "baby loading", "rocking cradle", "feeding".
/// 파일이 없으면 코랄핑크 CircularProgressIndicator로 안전 fallback.
class BabyLoading extends StatelessWidget {
  const BabyLoading({super.key, this.size = 96});
  final double size;

  static const _assetPath = 'assets/lottie/loading.json';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        _assetPath,
        repeat: true,
        animate: true,
        // Lottie 파일이 없거나 로드 실패 — 핑크 코끼리 달리기 애니메이션 fallback
        errorBuilder: (ctx, err, stack) => ElephantLoader(size: size),
      ),
    );
  }
}
