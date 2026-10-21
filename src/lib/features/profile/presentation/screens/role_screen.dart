import 'package:flutter/material.dart';

import '../../../../shared/theme/rumbo_colors.dart';
import '../components/role_card.dart';
import '../models/user_role.dart';

class RoleScreen extends StatelessWidget {
  final ValueChanged<UserRole> onChoose;

  const RoleScreen({super.key, required this.onChoose});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            const Text(
              'Paso final del registro',
              style: TextStyle(
                color: RumboColors.musgo,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '¿Cómo vas a usar Rumbo?',
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.7,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Puedes cambiar de rol cuando '
              'quieras desde tu perfil.',
              style: TextStyle(color: RumboColors.musgo, fontSize: 15),
            ),
            const SizedBox(height: 24),
            RoleCard(
              icon: Icons.groups_2_outlined,
              label: 'Participante',
              title: 'Quiero unirme a planes',
              text:
                  'Buscas caminatas y salidas '
                  'que ya existen, te unes al grupo '
                  'y hablas con la gente que va contigo.',
              onTap: () => onChoose(UserRole.participante),
            ),
            const SizedBox(height: 14),
            RoleCard(
              icon: Icons.route_outlined,
              label: 'Organizador',
              title: 'Quiero crear planes',
              text:
                  'Publicas la ruta, defines '
                  'cuántas personas necesitas y '
                  'apruebas a quienes piden un cupo.',
              highlighted: true,
              onTap: () => onChoose(UserRole.organizador),
            ),
          ],
        ),
      ),
    );
  }
}
