import 'package:flutter/material.dart';

class ElevationChart extends StatelessWidget {
  final List<double> values;
  final Color color;

  const ElevationChart({super.key, required this.values, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ElevationPainter(values, color),
      size: Size.infinite,
    );
  }
}

class ElevationPainter extends CustomPainter {
  final List<double> values;
  final Color color;

  ElevationPainter(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final line = Path();
    final fill = Path();

    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1 ? 0.0 : i / (values.length - 1) * size.width;

      final y = size.height - (values[i] / 100) * (size.height - 8) - 4;

      if (i == 0) {
        line.moveTo(x, y);
        fill.moveTo(x, size.height);
        fill.lineTo(x, y);
      } else {
        line.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }

    fill.lineTo(size.width, size.height);
    fill.close();

    canvas.drawPath(fill, Paint()..color = color.withValues(alpha: 0.13));

    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant ElevationPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}
