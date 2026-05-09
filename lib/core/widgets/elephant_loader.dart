import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 핑크 코끼리 달리기 + 코 들어 하트 방출 애니메이션.
///
/// 단순 도형 조합(원/타원/RRect/Path 단순 cubic)으로 안정적 렌더링.
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

  // 색상
  static const _bodyMid = Color(0xFFFFB5A7);
  static const _bodyShade = Color(0xFFFFD3CA);
  static const _earInner = Color(0xFFFFCFC4);
  static const _stroke = Color(0xFFD06A5C);
  static const _heartColor = Color(0xFFFF8FA0);
  static const _eyeColor = Color(0xFF3B2520);
  static const _smileColor = Color(0xFF7A3F38);
  static const _toePad = Color(0xFFFFE2DC);
  static const _shadow = Color(0x33D06A5C); // 20% alpha shadow

  double _raise(double t) =>
      math.max(0.0, math.sin((t - 0.5) * 2 * math.pi));

  Paint _fill(Color c) => Paint()
    ..color = c
    ..style = PaintingStyle.fill;

  Paint _stk(double w, [Color color = _stroke]) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final travel = math.sin(t * 2 * math.pi) * (w * 0.10);
    final bob = math.sin(t * 4 * math.pi) * 1.2;
    final cx = w * 0.5 + travel;
    final cy = h * 0.5 + bob;
    final s = w * 0.34;

    // 바닥 그림자
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + s * 0.95),
          width: s * 1.5,
          height: s * 0.16),
      _fill(_shadow),
    );

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(math.cos(t * 2 * math.pi) * 0.05);

    final raise = _raise(t);
    _drawElephant(canvas, s, t, raise);
    _drawTrunkHearts(canvas, s, t);

    canvas.restore();
  }

  void _drawElephant(Canvas canvas, double s, double t, double raise) {
    // ── 다리 4개 ───────────────────────────────────────────────
    void leg(double xOffset, double phase) {
      final yLift =
          math.max(0.0, math.sin(t * 4 * math.pi + phase)) * s * 0.18;
      final rect = Rect.fromLTWH(
          xOffset - s * 0.13, s * 0.30, s * 0.26, s * 0.50 - yLift);
      final rr = RRect.fromRectAndCorners(
        rect,
        bottomLeft: Radius.circular(s * 0.13),
        bottomRight: Radius.circular(s * 0.13),
      );
      canvas.drawRRect(rr, _fill(_bodyMid));
      canvas.drawRRect(rr, _stk(s * 0.075));
      canvas.drawCircle(
          Offset(xOffset, rect.bottom - s * 0.04),
          s * 0.07,
          _fill(_toePad));
    }

    leg(-s * 0.42, 0);
    leg(-s * 0.10, math.pi);
    leg(s * 0.18, 0);
    leg(s * 0.45, math.pi);

    // ── 꼬리 ───────────────────────────────────────────────────
    final tailWag = math.sin(t * 4 * math.pi) * s * 0.05;
    final tailPath = Path()
      ..moveTo(-s * 0.65, -s * 0.05)
      ..quadraticBezierTo(
        -s * 0.85,
        -s * 0.18 + tailWag,
        -s * 0.78,
        -s * 0.30 + tailWag,
      );
    canvas.drawPath(tailPath, _stk(s * 0.08));
    canvas.drawCircle(
        Offset(-s * 0.78, -s * 0.30 + tailWag), s * 0.05, _fill(_bodyMid));
    canvas.drawCircle(Offset(-s * 0.78, -s * 0.30 + tailWag), s * 0.05,
        _stk(s * 0.05));

    // ── 몸통 — 둥근 oval ──────────────────────────────────────
    final bodyRect = Rect.fromCenter(
        center: Offset(0, 0.08 * s), width: s * 1.45, height: s * 0.95);
    canvas.drawOval(bodyRect, _fill(_bodyMid));
    canvas.drawOval(bodyRect, _stk(s * 0.085));

    // 등 highlight
    final highlight = Path()
      ..moveTo(-s * 0.45, -s * 0.18)
      ..quadraticBezierTo(0, -s * 0.40, s * 0.45, -s * 0.18);
    canvas.drawPath(
      highlight,
      Paint()
        ..color = _bodyShade
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.10
        ..strokeCap = StrokeCap.round,
    );

    // ── 머리 ───────────────────────────────────────────────────
    final headCenter = Offset(s * 0.55, -s * 0.05);
    final headRadius = s * 0.50;
    canvas.drawCircle(headCenter, headRadius, _fill(_bodyMid));
    canvas.drawCircle(headCenter, headRadius, _stk(s * 0.085));

    // ── 큰 귀 (머리 좌측 위, 펄럭임) ──────────────────────────
    final earFlap = math.sin(t * 4 * math.pi) * 0.13;
    canvas.save();
    canvas.translate(s * 0.18, -s * 0.25); // 귀 위치 살짝 아래로
    canvas.rotate(-0.4 + earFlap);
    // 외곽
    final earOuter = Rect.fromCenter(
        center: Offset.zero, width: s * 0.55, height: s * 0.80);
    canvas.drawOval(earOuter, _fill(_bodyMid));
    canvas.drawOval(earOuter, _stk(s * 0.075));
    // 안쪽
    final earInner = Rect.fromCenter(
        center: const Offset(0, 4), width: s * 0.32, height: s * 0.55);
    canvas.drawOval(earInner, _fill(_earInner));
    canvas.restore();

    // 머리 위 짧은 머리카락
    canvas.drawPath(
      Path()
        ..moveTo(s * 0.55, -s * 0.55)
        ..quadraticBezierTo(s * 0.62, -s * 0.70, s * 0.70, -s * 0.58),
      _stk(s * 0.06),
    );

    // ── 트렁크 — 앞으로 길게 뻗어 들어올림 ─────────────────
    // 코끼리 트렁크는 머리 바로 옆에 짧게 매달리지 않고, 앞으로 길게
    // 뻗어 나갔다가 위/아래로 휘어짐. 두 가지 자세 사이를 raise(0~1)로 lerp.
    final trunkStart = Offset(s * 0.95, -s * 0.05);
    // DOWN — 앞으로 뻗었다가 끝이 살짝 아래로
    final downC1 = Offset(s * 1.30, s * 0.05);
    final downC2 = Offset(s * 1.45, s * 0.30);
    final downEnd = Offset(s * 1.30, s * 0.45);
    // UP — 앞으로 뻗었다가 위로 컬업 (코끼리 인사 자세)
    final upC1 = Offset(s * 1.35, -s * 0.20);
    final upC2 = Offset(s * 1.55, -s * 0.55);
    final upEnd = Offset(s * 1.40, -s * 0.85);

    final c1 = Offset.lerp(downC1, upC1, raise)!;
    final c2 = Offset.lerp(downC2, upC2, raise)!;
    final endPt = Offset.lerp(downEnd, upEnd, raise)!;

    final trunk = Path()
      ..moveTo(trunkStart.dx, trunkStart.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, endPt.dx, endPt.dy);
    // 두께를 시작은 굵게, 끝은 얇게 — 일반 strokeWidth로는 안 돼서
    // 굵은 stroke 한 번 + 약간 안쪽 stroke 한 번으로 시각적 보강
    canvas.drawPath(trunk, _stk(s * 0.22, _bodyMid));
    canvas.drawPath(trunk, _stk(s * 0.085));

    // 트렁크 주름 라인 3가닥 (디테일)
    final wrinklePaint = _stk(s * 0.04, _stroke.withValues(alpha: 0.55));
    Offset cubic(double u) {
      final v = 1 - u;
      return Offset(
        v * v * v * trunkStart.dx +
            3 * v * v * u * c1.dx +
            3 * v * u * u * c2.dx +
            u * u * u * endPt.dx,
        v * v * v * trunkStart.dy +
            3 * v * v * u * c1.dy +
            3 * v * u * u * c2.dy +
            u * u * u * endPt.dy,
      );
    }
    for (final pos in [0.30, 0.55, 0.78]) {
      final p = cubic(pos);
      final ahead = cubic(pos + 0.02);
      final dir = ahead - p;
      final len = dir.distance;
      if (len < 0.001) continue;
      final perp = Offset(-dir.dy / len, dir.dx / len) * (s * 0.10);
      canvas.drawLine(p - perp, p + perp, wrinklePaint);
    }

    // 코끝
    canvas.drawCircle(endPt, s * 0.08, _fill(_earInner));
    canvas.drawCircle(endPt, s * 0.08, _stk(s * 0.06));
    canvas.drawCircle(
        Offset(endPt.dx - s * 0.025, endPt.dy),
        s * 0.014,
        _fill(_smileColor));
    canvas.drawCircle(
        Offset(endPt.dx + s * 0.025, endPt.dy),
        s * 0.014,
        _fill(_smileColor));

    _trunkTip = endPt;

    // ── 눈 ────────────────────────────────────────────────────
    final eyeCenter = Offset(s * 0.62, -s * 0.12);
    canvas.drawCircle(eyeCenter, s * 0.06, _fill(Colors.white));
    canvas.drawCircle(eyeCenter, s * 0.06, _stk(s * 0.03));
    canvas.drawCircle(
        Offset(eyeCenter.dx + s * 0.012, eyeCenter.dy + s * 0.005),
        s * 0.038,
        _fill(_eyeColor));
    canvas.drawCircle(
        Offset(eyeCenter.dx + s * 0.022, eyeCenter.dy - s * 0.012),
        s * 0.016,
        _fill(Colors.white));

    // ── 미소 ──────────────────────────────────────────────────
    canvas.drawPath(
      Path()
        ..moveTo(s * 0.78, s * 0.04)
        ..quadraticBezierTo(s * 0.86, s * 0.13, s * 0.94, s * 0.04),
      _stk(s * 0.05, _smileColor),
    );

    // ── 볼터치 ────────────────────────────────────────────────
    canvas.drawCircle(
        Offset(s * 0.85, s * 0.04),
        s * 0.06,
        _fill(_heartColor.withValues(alpha: 0.55)));
  }

  Offset _trunkTip = Offset.zero;

  void _drawTrunkHearts(Canvas canvas, double s, double t) {
    const spawns = [0.55, 0.65, 0.75];
    const lifetime = 0.35;
    for (final spawnT in spawns) {
      double age = t - spawnT;
      if (age < 0) age += 1.0;
      if (age > lifetime) continue;
      final p = age / lifetime;
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
    final stk = Paint()
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
    canvas.drawPath(path, stk);
  }

  @override
  bool shouldRepaint(_ElephantPainter old) => old.t != t;
}
