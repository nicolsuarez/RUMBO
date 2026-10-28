import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/rumbo_colors.dart';
import '../../../../shared/painters/mountain_painter.dart';

class SplashScreen extends StatelessWidget {
  final VoidCallback onRegister;
  final VoidCallback onLogin;
  final VoidCallback onPreview;

  const SplashScreen({super.key, required this.onRegister, required this.onLogin, required this.onPreview});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RumboColors.monte,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: MountainPainter()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 28, 26, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.landscape,
                        color: RumboColors.guayacan,
                        size: 34,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Rumbo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Text(
                    'Planes al aire libre,\ncon gente de aquí.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      height: 1.03,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Farallones, Pance, Km 18, Cristo Rey. '
                    'Escoge tu rumbo o arma el tuyo.',
                    style: TextStyle(
                      color: Color(0xFFE6E8D6),
                      fontSize: 15.5,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: onRegister,
                    style: FilledButton.styleFrom(
                      backgroundColor: RumboColors.guayacan,
                      foregroundColor: RumboColors.tinta,
                      minimumSize: const Size.fromHeight(54),
                    ),
                    child: const Text(
                      'Crear cuenta',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: onLogin,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('Ya tengo cuenta'),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: onPreview,
                      child: const Text('Vista previa de desarrollo (sin autenticación)', style: TextStyle(color: Colors.white70)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
