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

    final cx = w * 0.5 + travel;
    final cy = h * 0.5 + bob;
    final s = w * 0.34; // 코끼리 크기 (대략 반지름)

    // ── 뒤따라가는 하트 파티클 (코끼리보다 먼저 그려서 코끼리 뒤에 위치) ──
    _drawHearts(canvas, cx, cy, s, t);

    canvas.save();
    canvas.translate(cx, cy);
    // 좌→우 진행 방향에 따라 미세하게 기울임 (좌측 이동 시 약간 좌향)
    final tilt = math.cos(t * 2 * math.pi) * 0.08;
    canvas.rotate(tilt);

    _drawElephant(canvas, s, t);
    canvas.restore();
  }

  void _drawHearts(Canvas canvas, double cx, double cy, double s, double t) {
    // 4개 하트 — phase 0, 0.25, 0.5, 0.75 로 동일 간격 spawn
    const count = 4;
    for (var i = 0; i < count; i++) {
      final phase = (t + i / count) % 1.0;
      // 코끼리 꼬리 위치(왼쪽 뒤)에서 방출 → 점점 왼쪽 뒤로 이동
      // 진행 방향(오른쪽)의 반대로 흘러간다는 인상.
      final dx = -s * 0.7 - phase * s * 1.2;
      final dy = -phase * s * 0.6 - s * 0.05;
      final scale = (1 - phase) * 0.9 + 0.1; // 살짝 커지며 사라짐
      final opacity = (1 - phase).clamp(0.0, 1.0) * 0.85;
      _heart(canvas, cx + dx, cy + dy, s * 0.12 * scale, opacity);
    }
  }

  void _heart(Canvas canvas, double cx, double cy, double r, double opacity) {
    if (r <= 0 || opacity <= 0) return;
    final fill = Paint()
      ..color = const Color(0xFFFF8FA0).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = _stroke.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.18
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    // 두 원 + 삼각으로 하트 — 베지어 곡선 사용
    path.moveTo(cx, cy + r * 0.6);
    path.cubicTo(
      cx + r * 1.2, cy - r * 0.4,
      cx + r * 0.4, cy - r * 1.2,
      cx, cy - r * 0.4,
    );
    path.cubicTo(
      cx - r * 0.4, cy - r * 1.2,
      cx - r * 1.2, cy - r * 0.4,
      cx, cy + r * 0.6,
    );
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
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
