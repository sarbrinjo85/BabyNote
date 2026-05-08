import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 앱 아이콘의 핑크 코끼리가 달리며 가끔 코를 들어 하트를 뿜는 로딩 애니메이션.
///
/// ── 사이클(기본 1.8s) ────────────────────────────────────────────────
/// 0.0~0.5 — 트렁크 아래 (달리기)
/// 0.5~1.0 — 트렁크 들어올림 + 하트 3개 순차 방출
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

  // 컬러 팔레트 — 앱 아이콘 톤
  static const _bodyMain = Color(0xFFFFB5A7); // 메인 코랄핑크
  static const _bodyShade = Color(0xFFFFCFC4); // 밝은 하이라이트
  static const _earInner = Color(0xFFFFC4B5); // 귀 안쪽
  static const _stroke = Color(0xFFD06A5C); // 진한 코랄 외곽
  static const _heartColor = Color(0xFFFF8FA0);
  static const _eyeColor = Color(0xFF4A2E2A);
  static const _smileColor = Color(0xFF7A3F38);
  static const _toeColor = Color(0xFFFFE2DC);

  /// 트렁크 들어올리기 envelope.
  double _raise(double t) =>
      math.max(0.0, math.sin((t - 0.5) * 2 * math.pi));

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final travel = math.sin(t * 2 * math.pi) * (w * 0.12);
    final bob = math.sin(t * 4 * math.pi) * 1.5;
    final cx = w * 0.5 + travel;
    final cy = h * 0.5 + bob;
    final s = w * 0.34;

    canvas.save();
    canvas.translate(cx, cy);
    final tilt = math.cos(t * 2 * math.pi) * 0.06;
    canvas.rotate(tilt);

    final raise = _raise(t);
    _drawElephant(canvas, s, t, raise);
    _drawTrunkHearts(canvas, s, t);

    canvas.restore();
  }

  Paint _fill(Color c) => Paint()
    ..color = c
    ..style = PaintingStyle.fill;

  Paint _strokePaint(double width) => Paint()
    ..color = _stroke
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  void _drawElephant(Canvas canvas, double s, double t, double raise) {
    // ── 다리 4개 — 통통한 발끝 ─────────────────────────────────
    void leg(double xOffset, double phase, {bool front = false}) {
      final yLift =
          math.max(0.0, math.sin(t * 4 * math.pi + phase)) * s * 0.20;
      final legTopY = s * 0.30;
      final footY = s * 0.78 - yLift;
      // 다리 stroke (몸과 연결)
      final p = Path()
        ..moveTo(xOffset, legTopY)
        ..lineTo(xOffset, footY);
      canvas.drawPath(p, _strokePaint(s * 0.22)..color = _bodyMain);
      // 발끝 — 살짝 큰 원 (둥근 발)
      canvas.drawCircle(Offset(xOffset, footY), s * 0.13, _fill(_bodyMain));
      canvas.drawCircle(Offset(xOffset, footY), s * 0.13, _strokePaint(s * 0.07));
      // 발끝 안쪽 핑크 하이라이트 (toe pad)
      canvas.drawCircle(
          Offset(xOffset, footY + s * 0.02), s * 0.06, _fill(_toeColor));
    }

    leg(-s * 0.42, 0);
    leg(-s * 0.12, math.pi);
    leg(s * 0.18, 0, front: true);
    leg(s * 0.42, math.pi, front: true);

    // ── 몸통 — 둥근 egg 셰이프 ────────────────────────────────
    final body = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(0, 0.05 * s), width: s * 1.45, height: s * 0.95));
    canvas.drawPath(body, _fill(_bodyMain));
    canvas.drawPath(body, _strokePaint(s * 0.085));

    // 몸통 위쪽 하이라이트 호 (어깨 라인)
    final highlight = Path()
      ..moveTo(-s * 0.45, -s * 0.20)
      ..quadraticBezierTo(0, -s * 0.42, s * 0.45, -s * 0.20);
    canvas.drawPath(
      highlight,
      Paint()
        ..color = _bodyShade
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.10
        ..strokeCap = StrokeCap.round,
    );

    // ── 꼬리 — 컬 + 끝 작은 점 ────────────────────────────────
    final tailWag = math.sin(t * 4 * math.pi) * s * 0.05;
    final tailPath = Path()
      ..moveTo(-s * 0.70, -s * 0.05)
      ..cubicTo(
        -s * 0.95, -s * 0.10 + tailWag,
        -s * 0.92, -s * 0.30 + tailWag,
        -s * 0.78, -s * 0.32 + tailWag,
      );
    canvas.drawPath(tailPath, _strokePaint(s * 0.08));
    // 꼬리 끝 brush
    canvas.drawCircle(
        Offset(-s * 0.78, -s * 0.32 + tailWag), s * 0.05, _fill(_bodyMain));
    canvas.drawCircle(Offset(-s * 0.78, -s * 0.32 + tailWag), s * 0.05,
        _strokePaint(s * 0.05));

    // ── 머리 ─────────────────────────────────────────────────
    final headCenter = Offset(s * 0.55, -s * 0.05);
    final headRadius = s * 0.50;
    canvas.drawCircle(headCenter, headRadius, _fill(_bodyMain));
    canvas.drawCircle(headCenter, headRadius, _strokePaint(s * 0.085));

    // ── 귀 — 큰 잎사귀 모양 + 안쪽 핑크 ────────────────────────
    final earCenter = Offset(s * 0.28, -s * 0.40);
    final earFlap = math.sin(t * 4 * math.pi) * 0.12;
    canvas.save();
    canvas.translate(earCenter.dx, earCenter.dy);
    canvas.rotate(earFlap - 0.25);
    // 귀 outer
    final earOuter = Path()
      ..addOval(Rect.fromCenter(
          center: Offset.zero, width: s * 0.50, height: s * 0.65));
    canvas.drawPath(earOuter, _fill(_bodyMain));
    canvas.drawPath(earOuter, _strokePaint(s * 0.08));
    // 귀 inner — 핑크 안쪽
    final earInner = Path()
      ..addOval(Rect.fromCenter(
          center: const Offset(0, 4), width: s * 0.30, height: s * 0.45));
    canvas.drawPath(earInner, _fill(_earInner));
    canvas.restore();

    // ── 머리 위 작은 머리카락 한 가닥 ──────────────────────────
    final hairPath = Path()
      ..moveTo(s * 0.50, -s * 0.50)
      ..quadraticBezierTo(s * 0.55, -s * 0.65, s * 0.62, -s * 0.55);
    canvas.drawPath(hairPath, _strokePaint(s * 0.05));

    // ── 트렁크 (아래 ↔ 위 컬업) ─────────────────────────────────
    final trunkStart = Offset(s * 0.95, -s * 0.05);
    // Down endpoints
    final downC1 = Offset(s * 1.18, -s * 0.05);
    final downC2 = Offset(s * 1.20, s * 0.22);
    final downEnd = Offset(s * 0.95, s * 0.32);
    // Up endpoints — 위로 컬
    final upC1 = Offset(s * 1.30, -s * 0.10);
    final upC2 = Offset(s * 1.35, -s * 0.55);
    final upEnd = Offset(s * 1.10, -s * 0.72);

    final c1 = Offset.lerp(downC1, upC1, raise)!;
    final c2 = Offset.lerp(downC2, upC2, raise)!;
    final endPt = Offset.lerp(downEnd, upEnd, raise)!;

    // 트렁크 두께 — 시작 굵고 끝 얇게 (taper)
    final trunkPath = Path()
      ..moveTo(trunkStart.dx, trunkStart.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, endPt.dx, endPt.dy);
    canvas.drawPath(trunkPath, _strokePaint(s * 0.20)..color = _bodyMain);
    canvas.drawPath(trunkPath, _strokePaint(s * 0.085));

    // 코끝 — 작은 둥근 패드
    canvas.drawCircle(endPt, s * 0.08, _fill(_earInner));
    canvas.drawCircle(endPt, s * 0.08, _strokePaint(s * 0.06));
    // 콧구멍 점
    canvas.drawCircle(
        Offset(endPt.dx - s * 0.025, endPt.dy),
        s * 0.014,
        _fill(_smileColor));
    canvas.drawCircle(
        Offset(endPt.dx + s * 0.025, endPt.dy),
        s * 0.014,
        _fill(_smileColor));

    _trunkTip = endPt;

    // ── 눈 — 흰자 highlight 점 ─────────────────────────────────
    final eyeCenter = Offset(s * 0.62, -s * 0.12);
    canvas.drawCircle(eyeCenter, s * 0.055, _fill(_eyeColor));
    canvas.drawCircle(
        Offset(eyeCenter.dx + s * 0.018, eyeCenter.dy - s * 0.015),
        s * 0.018,
        _fill(Colors.white));

    // ── 미소 — 작은 호 ─────────────────────────────────────────
    final smilePath = Path()
      ..moveTo(s * 0.78, s * 0.06)
      ..quadraticBezierTo(s * 0.85, s * 0.13, s * 0.92, s * 0.06);
    canvas.drawPath(smilePath, _strokePaint(s * 0.045)..color = _smileColor);

    // ── 볼터치 — 핑크 점 ───────────────────────────────────────
    final cheek = Paint()..color = _heartColor.withValues(alpha: 0.55);
    canvas.drawCircle(Offset(s * 0.85, -s * 0.02), s * 0.07, cheek);
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
