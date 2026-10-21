import 'package:flutter/material.dart';

import '../theme/rumbo_colors.dart';

class PlanArtPainter extends CustomPainter {
  final Color c1, c2;
  PlanArtPainter(this.c1, this.c2);
  @override
  void paint(Canvas canvas, Size s) {
    final rect = Offset.zero & s;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c2, c1],
        ).createShader(rect),
    );
    canvas.drawCircle(
      Offset(s.width * .78, s.height * .23),
      s.height * .11,
      Paint()..color = RumboColors.guayacan.withValues(alpha: .9),
    );
    final mountain1 = Path()
      ..moveTo(0, s.height)
      ..lineTo(0, s.height * .72)
      ..lineTo(s.width * .24, s.height * .35)
      ..lineTo(s.width * .43, s.height * .62)
      ..lineTo(s.width * .58, s.height * .48)
      ..lineTo(s.width, s.height * .80)
      ..lineTo(s.width, s.height)
      ..close();
    canvas.drawPath(mountain1, Paint()..color = c1.withValues(alpha: .9));
    final mountain2 = Path()
      ..moveTo(0, s.height)
      ..lineTo(0, s.height * .88)
      ..lineTo(s.width * .22, s.height * .64)
      ..lineTo(s.width * .46, s.height * .84)
      ..lineTo(s.width * .68, s.height * .67)
      ..lineTo(s.width, s.height * .92)
      ..lineTo(s.width, s.height)
      ..close();
    canvas.drawPath(
      mountain2,
      Paint()..color = const Color(0xFF1A2013).withValues(alpha: .9),
    );
  }

  @override
  bool shouldRepaint(covariant PlanArtPainter oldDelegate) =>
      oldDelegate.c1 != c1 || oldDelegate.c2 != c2;
}
