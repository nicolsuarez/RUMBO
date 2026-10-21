import 'package:flutter/material.dart';

import '../shared/theme/app_theme.dart';
import 'rumbo_shell.dart';

class RumboApp extends StatelessWidget {
  const RumboApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RUMBO',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const RumboShell(),
    );
  }
}
