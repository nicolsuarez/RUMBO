import 'package:flutter/material.dart';

import '../theme/rumbo_colors.dart';

class MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final rect = Offset.zero & s;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [RumboColors.monte, Color(0xFF8FA06B), Color(0xFF232B1A)],
        ).createShader(rect),
    );
    canvas.drawCircle(
      Offset(s.width * .77, s.height * .22),
      48,
      Paint()..color = RumboColors.guayacan.withValues(alpha: .92),
    );
    final p1 = Path()
      ..moveTo(0, s.height)
      ..lineTo(0, s.height * .68)
      ..lineTo(s.width * .28, s.height * .42)
      ..lineTo(s.width * .52, s.height * .65)
      ..lineTo(s.width * .66, s.height * .55)
      ..lineTo(s.width, s.height * .73)
      ..lineTo(s.width, s.height)
      ..close();
    canvas.drawPath(p1, Paint()..color = const Color(0xFF232B1A));
    final p2 = Path()
      ..moveTo(0, s.height)
      ..lineTo(0, s.height * .82)
      ..lineTo(s.width * .23, s.height * .64)
      ..lineTo(s.width * .49, s.height * .81)
      ..lineTo(s.width * .72, s.height * .69)
      ..lineTo(s.width, s.height * .85)
      ..lineTo(s.width, s.height)
      ..close();
    canvas.drawPath(p2, Paint()..color = const Color(0xFF1A2013));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
