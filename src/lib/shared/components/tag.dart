import 'package:flutter/material.dart';

import '../theme/rumbo_colors.dart';

class Tag extends StatelessWidget {
  final String text;
  final bool warn;
  final bool sun;

  const Tag(this.text, {super.key, this.warn = false, this.sun = false});

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor;

    final Color foregroundColor;

    if (warn) {
      backgroundColor = RumboColors.alerta.withValues(alpha: 0.14);
      foregroundColor = RumboColors.alerta;
    } else if (sun) {
      backgroundColor = RumboColors.guayacan.withValues(alpha: 0.20);
      foregroundColor = const Color(0xFF8A6A05);
    } else {
      backgroundColor = RumboColors.monte.withValues(alpha: 0.08);
      foregroundColor = RumboColors.monte2;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: foregroundColor,
        ),
      ),
    );
  }
}
