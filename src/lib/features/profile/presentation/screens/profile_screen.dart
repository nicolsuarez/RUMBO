import 'package:flutter/material.dart';

import '../../../../shared/components/section_title.dart';
import '../../../../shared/components/tag.dart';
import '../../../../shared/theme/rumbo_colors.dart';

import '../models/user_role.dart';

class ProfileScreen extends StatefulWidget {
  final UserRole role;
  final VoidCallback onToggleRole;

  const ProfileScreen({
    super.key,
    required this.role,
    required this.onToggleRole,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Set<String> interests = {'Senderismo', 'Amanecer', 'Aves'};

  @override
  Widget build(BuildContext context) {
    final org = widget.role == UserRole.organizador;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
      children: [
        // Avatar del usuario.
        const Center(
          child: CircleAvatar(
            radius: 42,
            backgroundColor: RumboColors.rosado,
            child: Text(
              'IN',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 24,
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Nombre del usuario.
        const Center(
          child: Text(
            'Ines Martínez',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
          ),
        ),

        // Rol seleccionado.
        Center(
          child: Text(
            org ? 'Organizador' : 'Participante',
            style: const TextStyle(color: RumboColors.musgo),
          ),
        ),

        const SectionTitle('Tus intereses'),

        // Intereses editables del prototipo.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              [
                'Senderismo',
                'Amanecer',
                'Ciclismo',
                'Aves',
                'Camping',
                'Fotografía',
                'Río',
              ].map((interest) {
                return FilterChip(
                  label: Text(interest),
                  selected: interests.contains(interest),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        interests.add(interest);
                      } else {
                        interests.remove(interest);
                      }
                    });
                  },
                );
              }).toList(),
        ),

        const SectionTitle('Tu modo actual'),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tag(org ? 'Organizador' : 'Participante', sun: org),

                const SizedBox(height: 10),

                Text(
                  org
                      ? 'Publicas rutas, defines cupos '
                            'y apruebas solicitudes.'
                      : 'Te unes a planes de otros '
                            'y hablas con tu grupo.',
                ),

                const SizedBox(height: 14),

                OutlinedButton(
                  onPressed: widget.onToggleRole,
                  child: Text(
                    org
                        ? 'Cambiar a modo participante'
                        : 'Cambiar a modo organizador',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
