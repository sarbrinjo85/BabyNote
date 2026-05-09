import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 핑크 코끼리 달리기 + 코 들어 하트 방출 애니메이션.
///
/// CustomPainter로 그리되 단순 도형 조합 대신 부드러운 베지어/그라디언트로
/// 일러스트 느낌을 살림.
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

  // 컬러 — 그라디언트 단계
  static const _bodyTop = Color(0xFFFFD3CA);    // 밝은 하이라이트
  static const _bodyMid = Color(0xFFFFB5A7);    // 메인 코랄
  static const _bodyBot = Color(0xFFF49585);    // 어두운 그림자
  static const _earOuter = Color(0xFFFFA693);   // 귀 바깥 (살짝 진함)
  static const _earInner = Color(0xFFFFCFC4);   // 귀 안쪽
  static const _stroke = Color(0xFFC8584A);     // 외곽선
  static const _heartColor = Color(0xFFFF8FA0);
  static const _eyeColor = Color(0xFF3B2520);
  static const _smileColor = Color(0xFF7A3F38);
  static const _toePad = Color(0xFFFFE2DC);
  static const _shadowColor = Color(0xFFD06A5C);

  double _raise(double t) =>
      math.max(0.0, math.sin((t - 0.5) * 2 * math.pi));

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final travel = math.sin(t * 2 * math.pi) * (w * 0.10);
    final bob = math.sin(t * 4 * math.pi) * 1.2;
    final cx = w * 0.5 + travel;
    final cy = h * 0.5 + bob;
    final s = w * 0.34;

    // 바닥 그림자 — 부드러운 타원
    final shadow = Paint()
      ..color = _shadowColor.withValues(alpha: 0.18)
      ..maskFilter = const ui.MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + s * 0.95),
          width: s * 1.6,
          height: s * 0.18),
      shadow,
    );

    canvas.save();
    canvas.translate(cx, cy);
    final tilt = math.cos(t * 2 * math.pi) * 0.05;
    canvas.rotate(tilt);

    final raise = _raise(t);
    _drawElephant(canvas, s, t, raise);
    _drawTrunkHearts(canvas, s, t);

    canvas.restore();
  }

  Paint _gradientFill(Rect rect, List<Color> colors,
      {Alignment begin = Alignment.topCenter,
      Alignment end = Alignment.bottomCenter}) {
    return Paint()
      ..shader = ui.Gradient.linear(
        Offset(rect.left + rect.width * (begin.x + 1) / 2,
            rect.top + rect.height * (begin.y + 1) / 2),
        Offset(rect.left + rect.width * (end.x + 1) / 2,
            rect.top + rect.height * (end.y + 1) / 2),
        colors,
      );
  }

  Paint _stk(double width, [Color color = _stroke]) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  void _drawElephant(Canvas canvas, double s, double t, double raise) {
    // 귀 그리기 헬퍼 — 잎사귀 cubic + 안쪽 핑크.
    final earFlap = math.sin(t * 4 * math.pi) * 0.12;
    void drawEar({
      required double cx,
      required double cy,
      required double w,
      required double h,
      required double rotation,
      required bool flipped,
    }) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(rotation + (flipped ? -earFlap : earFlap));
      final earRect = Rect.fromCenter(
          center: Offset.zero, width: w, height: h);
      final outerPath = Path();
      outerPath.moveTo(0, -h * 0.5);
      outerPath.cubicTo(w * 0.55, -h * 0.45, w * 0.65, h * 0.35,
          w * 0.05, h * 0.5);
      outerPath.cubicTo(-w * 0.55, h * 0.40, -w * 0.65, -h * 0.30,
          0, -h * 0.5);
      canvas.drawPath(
        outerPath,
        _gradientFill(
          earRect,
          [_earOuter, _bodyMid],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
      canvas.drawPath(outerPath, _stk(s * 0.075));
      // 안쪽 핑크
      final innerPath = Path();
      innerPath.moveTo(0, -h * 0.32);
      innerPath.cubicTo(w * 0.32, -h * 0.28, w * 0.40, h * 0.20,
          w * 0.02, h * 0.32);
      innerPath.cubicTo(-w * 0.32, h * 0.22, -w * 0.40, -h * 0.18,
          0, -h * 0.32);
      canvas.drawPath(innerPath, Paint()..color = _earInner);
      canvas.restore();
    }

    // ── 다리 4개 (몸통보다 먼저 — 몸이 위에서 가림) ─────────
    void leg(double xOffset, double phase) {
      final yLift =
          math.max(0.0, math.sin(t * 4 * math.pi + phase)) * s * 0.20;
      final legRect = Rect.fromLTWH(
          xOffset - s * 0.13, s * 0.30, s * 0.26, s * 0.55 - yLift);
      // 다리 fill (둥근 사각형 그라디언트)
      final rrect = RRect.fromRectAndCorners(
        legRect,
        bottomLeft: Radius.circular(s * 0.13),
        bottomRight: Radius.circular(s * 0.13),
      );
      canvas.drawRRect(
          rrect,
          _gradientFill(legRect, [_bodyTop, _bodyMid, _bodyBot],
              begin: Alignment.topLeft, end: Alignment.bottomRight));
      canvas.drawRRect(rrect, _stk(s * 0.075));
      // 발끝 toe pad
      canvas.drawCircle(
          Offset(xOffset, legRect.bottom - s * 0.04),
          s * 0.07,
          Paint()..color = _toePad);
    }

    leg(-s * 0.42, 0);
    leg(-s * 0.10, math.pi);
    leg(s * 0.18, 0);
    leg(s * 0.45, math.pi);

    // ── 꼬리 ───────────────────────────────────────────────────
    final tailWag = math.sin(t * 4 * math.pi) * s * 0.06;
    final tailPath = Path()
      ..moveTo(-s * 0.68, -s * 0.05)
      ..cubicTo(
        -s * 0.95, -s * 0.05 + tailWag,
        -s * 0.95, -s * 0.30 + tailWag,
        -s * 0.78, -s * 0.34 + tailWag,
      );
    canvas.drawPath(tailPath, _stk(s * 0.085));
    // 꼬리 끝 brush — 작은 잎
    canvas.save();
    canvas.translate(-s * 0.78, -s * 0.34 + tailWag);
    canvas.rotate(-0.6);
    final brushPath = Path()
      ..addOval(Rect.fromCenter(
          center: Offset.zero, width: s * 0.12, height: s * 0.08));
    canvas.drawPath(brushPath, Paint()..color = _bodyMid);
    canvas.drawPath(brushPath, _stk(s * 0.05));
    canvas.restore();

    // ── 몸통 — 둥근 콩(bean) 셰이프 + 그라디언트 ────────────
    final bodyRect = Rect.fromCenter(
        center: Offset(0, 0.05 * s), width: s * 1.55, height: s * 0.95);
    final bodyPath = Path();
    bodyPath.moveTo(-s * 0.70, 0);
    bodyPath.cubicTo(
      -s * 0.78, -s * 0.55, -s * 0.20, -s * 0.55, s * 0.10, -s * 0.45,
    );
    bodyPath.cubicTo(
      s * 0.55, -s * 0.40, s * 0.78, -s * 0.10, s * 0.78, s * 0.10,
    );
    bodyPath.cubicTo(
      s * 0.78, s * 0.40, s * 0.20, s * 0.50, -s * 0.30, s * 0.45,
    );
    bodyPath.cubicTo(
      -s * 0.65, s * 0.40, -s * 0.78, s * 0.20, -s * 0.70, 0,
    );
    canvas.drawPath(
      bodyPath,
      _gradientFill(bodyRect, [_bodyTop, _bodyMid, _bodyBot]),
    );
    canvas.drawPath(bodyPath, _stk(s * 0.085));

    // 배 highlight 곡선 — 풍성한 느낌
    final bellyHighlight = Path()
      ..moveTo(-s * 0.30, s * 0.30)
      ..quadraticBezierTo(0, s * 0.45, s * 0.40, s * 0.30);
    canvas.drawPath(
      bellyHighlight,
      Paint()
        ..color = _bodyTop.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.10
        ..strokeCap = StrokeCap.round,
    );

    // ── 머리 — 큰 둥근 원 + 그라디언트 ──────────────────────
    final headCenter = Offset(s * 0.55, -s * 0.10);
    final headRadius = s * 0.55;
    final headRect = Rect.fromCircle(center: headCenter, radius: headRadius);
    canvas.drawCircle(
        headCenter,
        headRadius,
        _gradientFill(headRect, [_bodyTop, _bodyMid, _bodyBot]));
    canvas.drawCircle(headCenter, headRadius, _stk(s * 0.085));

    // ── 큰 귀 — 머리 좌측에 살짝 큰 잎사귀처럼 ──────────────
    // 사용자 요청: 귀를 더 크게. 단, 얼굴/몸을 가리지 않도록 헤드 좌측 위로
    // 약간 떨어뜨리고 회전 각을 조절해 자연스러운 펄럭임.
    drawEar(
      cx: s * 0.20,         // 머리 가장자리 부근
      cy: -s * 0.50,        // 살짝 위
      w: s * 0.70,          // 가로 큼
      h: s * 0.95,          // 세로 큼 (머리보다 살짝 작은 사이즈)
      rotation: -0.55,
      flipped: true,
    );

    // ── 머리 위 머리카락 한 가닥 ──────────────────────────────
    final hairPath = Path()
      ..moveTo(s * 0.55, -s * 0.62)
      ..quadraticBezierTo(s * 0.62, -s * 0.78, s * 0.72, -s * 0.65);
    canvas.drawPath(hairPath, _stk(s * 0.06));

    // ── 트렁크 — 두꺼움→얇음 taper, 가는 주름 라인 ─────────
    final trunkStart = Offset(s * 0.95, -s * 0.10);
    final downC1 = Offset(s * 1.20, -s * 0.10);
    final downC2 = Offset(s * 1.22, s * 0.20);
    final downEnd = Offset(s * 0.97, s * 0.32);
    final upC1 = Offset(s * 1.30, -s * 0.15);
    final upC2 = Offset(s * 1.35, -s * 0.55);
    final upEnd = Offset(s * 1.10, -s * 0.78);

    final c1 = Offset.lerp(downC1, upC1, raise)!;
    final c2 = Offset.lerp(downC2, upC2, raise)!;
    final endPt = Offset.lerp(downEnd, upEnd, raise)!;

    // 트렁크 본체
    final trunk = Path()
      ..moveTo(trunkStart.dx, trunkStart.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, endPt.dx, endPt.dy);
    canvas.drawPath(
      trunk,
      Paint()
        ..color = _bodyMid
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.22
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(trunk, _stk(s * 0.085));

    // 트렁크 주름선 3개 (디테일)
    final wrinklePaint = _stk(s * 0.04, _stroke.withValues(alpha: 0.55));
    for (final pos in [0.30, 0.55, 0.78]) {
      final p = _approxPointOnCubic(trunkStart, c1, c2, endPt, pos);
      // 주름 짧은 선 — 진행 방향 수직
      final ahead = _approxPointOnCubic(trunkStart, c1, c2, endPt, pos + 0.02);
      final dir = Offset(ahead.dx - p.dx, ahead.dy - p.dy);
      final len = math.sqrt(dir.dx * dir.dx + dir.dy * dir.dy);
      if (len < 0.001) continue;
      final perp = Offset(-dir.dy / len, dir.dx / len) * (s * 0.10);
      canvas.drawLine(p - perp, p + perp, wrinklePaint);
    }

    // 코끝 패드
    canvas.drawCircle(endPt, s * 0.085, Paint()..color = _earInner);
    canvas.drawCircle(endPt, s * 0.085, _stk(s * 0.06));
    // 콧구멍
    canvas.drawCircle(
        Offset(endPt.dx - s * 0.025, endPt.dy),
        s * 0.014,
        Paint()..color = _smileColor);
    canvas.drawCircle(
        Offset(endPt.dx + s * 0.025, endPt.dy),
        s * 0.014,
        Paint()..color = _smileColor);

    _trunkTip = endPt;

    // ── 눈 — 흰자 + 검정 + 화이트 하이라이트 ──────────────
    final eyeCenter = Offset(s * 0.62, -s * 0.16);
    canvas.drawCircle(
        eyeCenter, s * 0.07, Paint()..color = Colors.white);
    canvas.drawCircle(
        eyeCenter, s * 0.07, _stk(s * 0.035));
    canvas.drawCircle(
        Offset(eyeCenter.dx + s * 0.015, eyeCenter.dy + s * 0.005),
        s * 0.045,
        Paint()..color = _eyeColor);
    canvas.drawCircle(
        Offset(eyeCenter.dx + s * 0.025, eyeCenter.dy - s * 0.012),
        s * 0.018,
        Paint()..color = Colors.white);

    // 속눈썹 3가닥 (작은 직선)
    final lashPaint = _stk(s * 0.025, _eyeColor);
    canvas.drawLine(
        Offset(eyeCenter.dx - s * 0.05, eyeCenter.dy - s * 0.06),
        Offset(eyeCenter.dx - s * 0.07, eyeCenter.dy - s * 0.10),
        lashPaint);
    canvas.drawLine(
        Offset(eyeCenter.dx, eyeCenter.dy - s * 0.07),
        Offset(eyeCenter.dx, eyeCenter.dy - s * 0.12),
        lashPaint);
    canvas.drawLine(
        Offset(eyeCenter.dx + s * 0.05, eyeCenter.dy - s * 0.06),
        Offset(eyeCenter.dx + s * 0.07, eyeCenter.dy - s * 0.10),
        lashPaint);

    // ── 미소 ───────────────────────────────────────────────
    final smilePath = Path()
      ..moveTo(s * 0.78, s * 0.02)
      ..quadraticBezierTo(s * 0.86, s * 0.12, s * 0.94, s * 0.02);
    canvas.drawPath(smilePath, _stk(s * 0.05, _smileColor));

    // ── 볼터치 (양 볼) ─────────────────────────────────────
    final cheek = Paint()
      ..color = _heartColor.withValues(alpha: 0.55)
      ..maskFilter = const ui.MaskFilter.blur(BlurStyle.normal, 1.5);
    canvas.drawCircle(Offset(s * 0.86, s * 0.04), s * 0.07, cheek);
    canvas.drawCircle(Offset(s * 0.40, s * 0.02), s * 0.05, cheek);
  }

  // 베지어 곡선 위 근사 좌표 (트렁크 주름 위치용)
  Offset _approxPointOnCubic(
      Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final u = 1 - t;
    final a = u * u * u;
    final b = 3 * u * u * t;
    final c = 3 * u * t * t;
    final d = t * t * t;
    return Offset(
      a * p0.dx + b * p1.dx + c * p2.dx + d * p3.dx,
      a * p0.dy + b * p1.dy + c * p2.dy + d * p3.dy,
    );
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
