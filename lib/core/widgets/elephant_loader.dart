import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 앱 아이콘의 핑크 코끼리가 달려가는 로딩 애니메이션.
///
/// ── 왜 CustomPainter? ──────────────────────────────────────────────
/// Lottie JSON은 수천 줄의 키프레임으로 손으로 작성하기 어려움.
/// CustomPainter는 코드로 그리고 애니메이션도 코드로 제어 → 가볍고 유연.
/// 이미지/JSON 의존성도 없어 빌드 사이즈 부담 X.
///
/// ── 구성 ────────────────────────────────────────────────────────────
/// - 코끼리(몸/머리/귀/코/다리) 아이콘 톤(코랄핑크 + 진한 코랄 stroke)
/// - 가로로 좌→우 이동 후 반복 (달려가는 느낌)
/// - 다리 4개 교차 흔들림, 코·귀 가벼운 보브 모션
class ElephantLoader extends StatefulWidget {
  const ElephantLoader({
    super.key,
    this.size = 96,
    this.cycle = const Duration(milliseconds: 1400),
  });

  final double size;
  final Duration cycle;

  @override
  State<ElephantLoader> createState() => _ElephantLoaderState();
}

class _ElephantLoaderState extends State<ElephantLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl =
      AnimationController(vsync: this, duration: widget.cycle)..repeat();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctl,
        builder: (_, __) => CustomPaint(
          painter: _ElephantPainter(t: _ctl.value),
        ),
      ),
    );
  }
}

class _ElephantPainter extends CustomPainter {
  _ElephantPainter({required this.t});

  /// 0..1 반복.
  final double t;

  // 앱 아이콘과 동일 톤
  static const _fillLight = Color(0xFFFCD3CB); // 옅은 코랄(귀/코끝)
  static const _fillBody = Color(0xFFFFB5A7);  // 메인 코랄
  static const _stroke   = Color(0xFFE07A6B);  // 진한 코랄 외곽
  static const _eyeColor = Color(0xFF6B3F38);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 좌→우 트랜슬레이션 (한 cycle에 좌→우 한번 — wrap)
    // 화면 너비의 60% 폭 안에서 왔다갔다
    final travel = math.sin(t * 2 * math.pi) * (w * 0.18);
    // 몸 전체 가벼운 보브
    final bob = math.sin(t * 4 * math.pi) * 1.5;

    canvas.save();
    canvas.translate(w * 0.5 + travel, h * 0.5 + bob);
    // 좌→우 진행 방향에 따라 미세하게 기울임 (좌측 이동 시 약간 좌향)
    final tilt = math.cos(t * 2 * math.pi) * 0.08;
    canvas.rotate(tilt);

    final s = w * 0.34; // 코끼리 크기 (대략 반지름)
    _drawElephant(canvas, s, t);
    canvas.restore();
  }

  void _drawElephant(Canvas canvas, double s, double t) {
    final fill = Paint()
      ..color = _fillBody
      ..style = PaintingStyle.fill;
    final fillLight = Paint()
      ..color = _fillLight
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = _stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.07
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // ── 다리 4개 — 교차 모션 ────────────────────────────────────
    // 앞다리 한 쌍 / 뒷다리 한 쌍이 phase 반대로
    void leg(double xOffset, double phase) {
      final yLift =
          math.max(0.0, math.sin(t * 4 * math.pi + phase)) * s * 0.18;
      final p = Path()
        ..moveTo(xOffset, s * 0.45)
        ..lineTo(xOffset, s * 0.85 - yLift);
      canvas.drawPath(p, stroke..strokeWidth = s * 0.18);
      canvas.drawCircle(
          Offset(xOffset, s * 0.85 - yLift), s * 0.09, fill);
      canvas.drawCircle(
          Offset(xOffset, s * 0.85 - yLift),
          s * 0.09,
          stroke..strokeWidth = s * 0.07);
    }

    leg(-s * 0.45, 0);          // 뒤
    leg(-s * 0.15, math.pi);    // 뒤 (반대 phase)
    leg(s * 0.18, 0);           // 앞
    leg(s * 0.42, math.pi);     // 앞 (반대 phase)

    // ── 몸통 ────────────────────────────────────────────────────
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(0, 0.05 * s), width: s * 1.3, height: s * 0.85),
      Radius.circular(s * 0.42),
    );
    canvas.drawRRect(body, fill);
    canvas.drawRRect(body, stroke..strokeWidth = s * 0.08);

    // ── 꼬리 (몸 뒤쪽) ──────────────────────────────────────────
    final tailWag = math.sin(t * 4 * math.pi) * s * 0.04;
    final tailPath = Path()
      ..moveTo(-s * 0.65, -0.05 * s)
      ..quadraticBezierTo(-s * 0.85, -s * 0.15 + tailWag,
          -s * 0.78, -s * 0.25 + tailWag);
    canvas.drawPath(tailPath, stroke..strokeWidth = s * 0.07);

    // ── 머리 ────────────────────────────────────────────────────
    final headCenter = Offset(s * 0.55, -s * 0.05);
    canvas.drawCircle(headCenter, s * 0.45, fill);
    canvas.drawCircle(
        headCenter, s * 0.45, stroke..strokeWidth = s * 0.08);

    // ── 귀 (머리 안쪽 약간 위) ─────────────────────────────────
    final earCenter = Offset(s * 0.32, -s * 0.32);
    final earFlap = math.sin(t * 4 * math.pi) * 0.1;
    canvas.save();
    canvas.translate(earCenter.dx, earCenter.dy);
    canvas.rotate(earFlap);
    final earPath = Path()
      ..addOval(Rect.fromCenter(
          center: Offset.zero, width: s * 0.45, height: s * 0.55));
    canvas.drawPath(earPath, fillLight);
    canvas.drawPath(earPath, stroke..strokeWidth = s * 0.07);
    canvas.restore();

    // ── 코 (트렁크) — S자 곡선, 가벼운 보브 ─────────────────────
    final trunkBob = math.sin(t * 4 * math.pi) * s * 0.05;
    final trunk = Path()
      ..moveTo(s * 0.95, -s * 0.05)
      ..cubicTo(
        s * 1.20 + trunkBob, -s * 0.05,
        s * 1.20 + trunkBob, s * 0.25,
        s * 0.95, s * 0.30 + trunkBob,
      );
    canvas.drawPath(trunk, stroke..strokeWidth = s * 0.18);
    // 코끝 작은 원
    canvas.drawCircle(
        Offset(s * 0.95, s * 0.30 + trunkBob), s * 0.07, fillLight);
    canvas.drawCircle(
        Offset(s * 0.95, s * 0.30 + trunkBob),
        s * 0.07,
        stroke..strokeWidth = s * 0.06);

    // ── 눈 ──────────────────────────────────────────────────────
    final eye = Paint()..color = _eyeColor;
    canvas.drawCircle(Offset(s * 0.65, -s * 0.10), s * 0.04, eye);

    // ── 볼 분홍 점 ─────────────────────────────────────────────
    final cheek = Paint()
      ..color = const Color(0xFFFF8FA0).withValues(alpha: 0.6);
    canvas.drawCircle(Offset(s * 0.78, s * 0.04), s * 0.06, cheek);
  }

  @override
  bool shouldRepaint(_ElephantPainter old) => old.t != t;
}
