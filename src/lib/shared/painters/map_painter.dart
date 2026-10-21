import 'package:flutter/material.dart';

import '../theme/rumbo_colors.dart';

class DemoMap extends StatelessWidget {
  final double height;
  const DemoMap({super.key, this.height = 200});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: CustomPaint(painter: MapPainter()),
    ),
  );
}

class MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFDCE3CB));
    final contour = Paint()
      ..color = const Color(0xFFA6A283)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = 0; i < 5; i++) {
      final p = Path()
        ..moveTo(0, s.height * (.25 + i * .12))
        ..cubicTo(
          s.width * .2,
          s.height * (.14 + i * .12),
          s.width * .35,
          s.height * (.42 + i * .08),
          s.width * .55,
          s.height * (.28 + i * .11),
        )
        ..cubicTo(
          s.width * .72,
          s.height * (.18 + i * .1),
          s.width * .85,
          s.height * (.35 + i * .08),
          s.width,
          s.height * (.26 + i * .11),
        );
      canvas.drawPath(p, contour);
    }
    final river = Paint()
      ..color = const Color(0xFF8FBBB0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawPath(
      Path()
        ..moveTo(0, s.height * .82)
        ..quadraticBezierTo(
          s.width * .48,
          s.height * .68,
          s.width,
          s.height * .78,
        ),
      river,
    );
    final route = Paint()
      ..color = RumboColors.monte
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(s.width * .12, s.height * .72)
        ..cubicTo(
          s.width * .3,
          s.height * .6,
          s.width * .42,
          s.height * .38,
          s.width * .55,
          s.height * .45,
        )
        ..cubicTo(
          s.width * .68,
          s.height * .52,
          s.width * .72,
          s.height * .28,
          s.width * .88,
          s.height * .22,
        ),
      route,
    );
    canvas.drawCircle(
      Offset(s.width * .48, s.height * .46),
      10,
      Paint()..color = RumboColors.guayacan,
    );
    canvas.drawCircle(
      Offset(s.width * .48, s.height * .46),
      4,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
