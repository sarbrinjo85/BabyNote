import 'package:flutter/material.dart';

/// AppBar 등에서 사용하는 코랄핑크 fill + 진한 코랄 stroke 타이틀.
///
/// Flutter TextStyle.foreground는 단일 Paint만 받기 때문에 fill/stroke
/// 두 효과를 모두 표현하려면 Stack에 두 Text를 겹쳐 그림.
class StrokedTitle extends StatelessWidget {
  const StrokedTitle(
    this.text, {
    super.key,
    this.fontSize = 32,
    this.fillColor = const Color(0xFFFE7D81),
    this.strokeColor = const Color(0xFFA43F45),
    this.strokeWidth = 3.0,
  });

  final String text;
  final double fontSize;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.3,
    );
    return Stack(
      children: [
        Text(
          text,
          style: baseStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..color = strokeColor,
          ),
        ),
        Text(
          text,
          style: baseStyle.copyWith(color: fillColor),
        ),
      ],
    );
  }
}
