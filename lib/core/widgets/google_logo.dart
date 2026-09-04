import 'package:flutter/widgets.dart';

/// The four-color Google "G" mark, drawn to spec for third-party
/// "Sign in with Google" buttons — geometry matches Google's published
/// brand assets for this exact use case.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 19});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 20;
    canvas.save();
    canvas.scale(scale, scale);
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFF4285F4);
    canvas.drawPath(
      Path()
        ..moveTo(19.6, 10.23)
        ..cubicTo(19.6, 9.55, 19.54, 8.87, 19.41, 8.21)
        ..lineTo(10, 8.21)
        ..lineTo(10, 12.04)
        ..lineTo(15.4, 12.04)
        ..cubicTo(15.17, 13.29, 14.44, 14.36, 13.4, 15.07)
        ..lineTo(13.4, 17.57)
        ..lineTo(16.63, 17.57)
        ..cubicTo(18.53, 15.82, 19.6, 13.24, 19.6, 10.23)
        ..close(),
      paint,
    );

    paint.color = const Color(0xFF34A853);
    canvas.drawPath(
      Path()
        ..moveTo(10, 20)
        ..cubicTo(12.7, 20, 14.97, 19.11, 16.63, 17.58)
        ..lineTo(13.4, 15.08)
        ..cubicTo(12.5, 15.68, 11.34, 16.03, 10, 16.03)
        ..cubicTo(7.4, 16.03, 5.2, 14.27, 4.4, 11.91)
        ..lineTo(1.06, 11.91)
        ..lineTo(1.06, 14.5)
        ..cubicTo(2.71, 17.78, 6.1, 20, 10, 20)
        ..close(),
      paint,
    );

    paint.color = const Color(0xFFFBBC05);
    canvas.drawPath(
      Path()
        ..moveTo(4.4, 11.9)
        ..cubicTo(4.19, 11.3, 4.07, 10.66, 4.07, 10)
        ..cubicTo(4.07, 9.34, 4.19, 8.7, 4.4, 8.1)
        ..lineTo(4.4, 5.5)
        ..lineTo(1.06, 5.5)
        ..cubicTo(0.39, 6.83, 0, 8.32, 0, 10)
        ..cubicTo(0, 11.68, 0.39, 13.17, 1.06, 14.5)
        ..lineTo(4.4, 11.9)
        ..close(),
      paint,
    );

    paint.color = const Color(0xFFEA4335);
    canvas.drawPath(
      Path()
        ..moveTo(10, 3.98)
        ..cubicTo(11.47, 3.98, 12.79, 4.48, 13.83, 5.48)
        ..lineTo(16.7, 2.61)
        ..cubicTo(14.96, 0.99, 12.7, 0, 10, 0)
        ..cubicTo(6.1, 0, 2.71, 2.22, 1.06, 5.5)
        ..lineTo(4.4, 8.1)
        ..cubicTo(5.2, 5.74, 7.4, 3.98, 10, 3.98)
        ..close(),
      paint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
