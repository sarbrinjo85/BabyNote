import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 앱 아이콘의 핑크 코끼리가 달리며 가끔 코를 들어 하트를 뿜는 로딩 애니메이션.
///
/// 사이클(기본 1.4초) 안에서:
///   0.0~0.5  — 트렁크 아래로 (달리기)
///   0.5~1.0  — 트렁크 위로 들어올림 + 하트 3개 순차 방출
class ElephantLoader extends StatefulWidget {
  const ElephantLoader({
    super.key,
    this.size = 96,
    this.cycle = const Duration(milliseconds: 1800),
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
        builder: (_, child) => CustomPaint(
          painter: _ElephantPainter(t: _ctl.value),
        ),
      ),
    );
  }
}

class _ElephantPainter extends CustomPainter {
  _ElephantPainter({required this.t});
  final double t;

  static const _fillLight = Color(0xFFFCD3CB);
  static const _fillBody = Color(0xFFFFB5A7);
  static const _stroke = Color(0xFFE07A6B);
  static const _heartColor = Color(0xFFFF8FA0);
  static const _eyeColor = Color(0xFF6B3F38);

  /// 트렁크 들어올리기 envelope — t in [0.5, 1.0]에서 0→1→0 부드러운 봉우리.
  /// t < 0.5 이면 0 (트렁크 아래로).
  double _raise(double t) =>
      math.max(0.0, math.sin((t - 0.5) * 2 * math.pi));

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final travel = math.sin(t * 2 * math.pi) * (w * 0.18);
    final bob = math.sin(t * 4 * math.pi) * 1.5;
    final cx = w * 0.5 + travel;
    final cy = h * 0.5 + bob;
    final s = w * 0.34;

    canvas.save();
    canvas.translate(cx, cy);
    final tilt = math.cos(t * 2 * math.pi) * 0.08;
    canvas.rotate(tilt);

    final raise = _raise(t);
    _drawElephant(canvas, s, t, raise);
    _drawTrunkHearts(canvas, s, t);

    canvas.restore();
  }

  void _drawElephant(Canvas canvas, double s, double t, double raise) {
    final fill = Paint()
      ..color = _fillBody
      ..style = PaintingStyle.fill;
    final fillLight = Paint()
      ..color = _fillLight
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = _stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.08
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // ── 다리 4개 — 교차 모션 ───────────────────────────────────
    void leg(double xOffset, double phase) {
      final yLift =
          math.max(0.0, math.sin(t * 4 * math.pi + phase)) * s * 0.18;
      final p = Path()
        ..moveTo(xOffset, s * 0.45)
        ..lineTo(xOffset, s * 0.85 - yLift);
      canvas.drawPath(p, stroke..strokeWidth = s * 0.18);
      canvas.drawCircle(
          Offset(xOffset, s * 0.85 - yLift), s * 0.09, fill);
      canvas.drawCircle(Offset(xOffset, s * 0.85 - yLift), s * 0.09,
          stroke..strokeWidth = s * 0.07);
    }

    leg(-s * 0.45, 0);
    leg(-s * 0.15, math.pi);
    leg(s * 0.18, 0);
    leg(s * 0.42, math.pi);

    // ── 몸통 ───────────────────────────────────────────────────
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(0, 0.05 * s), width: s * 1.3, height: s * 0.85),
      Radius.circular(s * 0.42),
    );
    canvas.drawRRect(body, fill);
    canvas.drawRRect(body, stroke..strokeWidth = s * 0.08);

    // ── 꼬리 ───────────────────────────────────────────────────
    final tailWag = math.sin(t * 4 * math.pi) * s * 0.04;
    final tailPath = Path()
      ..moveTo(-s * 0.65, -0.05 * s)
      ..quadraticBezierTo(
        -s * 0.85,
        -s * 0.15 + tailWag,
        -s * 0.78,
        -s * 0.25 + tailWag,
      );
    canvas.drawPath(tailPath, stroke..strokeWidth = s * 0.07);

    // ── 머리 ───────────────────────────────────────────────────
    final headCenter = Offset(s * 0.55, -s * 0.05);
    canvas.drawCircle(headCenter, s * 0.45, fill);
    canvas.drawCircle(
        headCenter, s * 0.45, stroke..strokeWidth = s * 0.08);

    // ── 귀 ─────────────────────────────────────────────────────
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

    // ── 트렁크 (들어올리기 가능) ───────────────────────────────
    // raise=0 → 아래로 S자, raise=1 → 위로 컬업.
    final trunkStart = Offset(s * 0.95, -s * 0.05);
    // Down endpoints
    final downC1 = Offset(s * 1.20, -s * 0.05);
    final downC2 = Offset(s * 1.20, s * 0.25);
    final downEnd = Offset(s * 0.95, s * 0.30);
    // Up endpoints (코를 들고 위로 컬)
    final upC1 = Offset(s * 1.25, -s * 0.10);
    final upC2 = Offset(s * 1.30, -s * 0.55);
    final upEnd = Offset(s * 1.05, -s * 0.70);

    final c1 = Offset.lerp(downC1, upC1, raise)!;
    final c2 = Offset.lerp(downC2, upC2, raise)!;
    final endPt = Offset.lerp(downEnd, upEnd, raise)!;

    final trunk = Path()
      ..moveTo(trunkStart.dx, trunkStart.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, endPt.dx, endPt.dy);
    canvas.drawPath(trunk, stroke..strokeWidth = s * 0.18);
    // 코끝
    canvas.drawCircle(endPt, s * 0.07, fillLight);
    canvas.drawCircle(endPt, s * 0.07, stroke..strokeWidth = s * 0.06);

    // 코끝 좌표를 캐시에 저장(하트 방출 위치) — Path object 통해서가 아니라 바로 사용
    _trunkTip = endPt;

    // ── 눈 ─────────────────────────────────────────────────────
    final eye = Paint()..color = _eyeColor;
    canvas.drawCircle(Offset(s * 0.65, -s * 0.10), s * 0.04, eye);

    // ── 볼 ─────────────────────────────────────────────────────
    final cheek = Paint()..color = _heartColor.withValues(alpha: 0.6);
    canvas.drawCircle(Offset(s * 0.78, s * 0.04), s * 0.06, cheek);
  }

  // 트렁크 끝 위치 (현재 프레임 기준) — 하트 방출에 사용
  Offset _trunkTip = Offset.zero;

  void _drawTrunkHearts(Canvas canvas, double s, double t) {
    // 하트 3개를 trunk가 위로 올라가기 시작한 시점부터 순차 방출.
    // spawnT 0.55 / 0.65 / 0.75 — 모두 raise envelope 활성 구간 안.
    const spawns = [0.55, 0.65, 0.75];
    const lifetime = 0.35; // t 단위
    for (final spawnT in spawns) {
      double age = t - spawnT;
      if (age < 0) age += 1.0; // 사이클 wrap
      if (age > lifetime) continue; // 아직 살아있지 않음
      final p = age / lifetime; // 0..1

      // 하트가 코끝 부근에서 솟아 위로 흩어짐
      final wiggle = math.sin(p * math.pi * 2) * s * 0.06;
      final hx = _trunkTip.dx + wiggle;
      final hy = _trunkTip.dy - p * s * 0.7;
      final scale = 0.5 + p * 0.7;
      final opacity = (1 - p).clamp(0.0, 1.0);
      _heart(canvas, hx, hy, s * 0.10 * scale, opacity);
    }
  }

  void _heart(Canvas canvas, double cx, double cy, double r, double opacity) {
    if (r <= 0 || opacity <= 0) return;
    final fill = Paint()
      ..color = _heartColor.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = _stroke.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.18
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
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

  @override
  bool shouldRepaint(_ElephantPainter old) => old.t != t;
}
