import 'package:flutter/material.dart';

/// 구글 브랜드 가이드에 가깝게 단순화한 G 마크 (외부 에셋 없이 표시)
class GoogleBrandIcon extends StatelessWidget {
  const GoogleBrandIcon({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = w * 0.12;
    final r = Rect.fromLTWH(stroke * 0.5, stroke * 0.5, w - stroke, h - stroke);

    const blue = Color(0xFF4285F4);
    const green = Color(0xFF34A853);
    const yellow = Color(0xFFFBBC05);
    const red = Color(0xFFEA4335);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    arcPaint.color = blue;
    canvas.drawArc(r, -1.2, 1.2, false, arcPaint);
    arcPaint.color = red;
    canvas.drawArc(r, -0.35, 1.0, false, arcPaint);
    arcPaint.color = yellow;
    canvas.drawArc(r, 0.55, 1.0, false, arcPaint);
    arcPaint.color = green;
    canvas.drawArc(r, 1.55, 1.15, false, arcPaint);

    final linePaint = Paint()
      ..color = blue
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.48, h * 0.48),
      Offset(w * 0.88, h * 0.48),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
