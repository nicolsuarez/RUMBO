import 'package:flutter/material.dart';

import 'home_screen.dart';

/// Adaptador de navegación: mantiene la API usada por RumboShell,
/// mientras HomeScreen conserva la interfaz original de RUMBO.
class PlansHomePage extends StatelessWidget {
  const PlansHomePage({
    super.key,
    required this.userName,
    required this.onExplore,
  });

  final String userName;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return HomeScreen(userName: userName, onExplore: onExplore);
  }
}
