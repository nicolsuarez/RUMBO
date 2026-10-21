import 'package:flutter/material.dart';

import 'rumbo_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: RumboColors.niebla,
      colorScheme: ColorScheme.fromSeed(
        seedColor: RumboColors.monte,
        primary: RumboColors.monte,
        secondary: RumboColors.guayacan,
        surface: RumboColors.papel,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w800,
          color: RumboColors.tinta,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w800,
          color: RumboColors.tinta,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w700,
          color: RumboColors.tinta,
        ),
        bodyMedium: TextStyle(color: RumboColors.tinta, height: 1.45),
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: RumboColors.guayacan,
        primary: RumboColors.guayacan,
        surface: const Color(0xFF232B1A),
      ),
      scaffoldBackgroundColor: const Color(0xFF171D10),
    );
  }
}
