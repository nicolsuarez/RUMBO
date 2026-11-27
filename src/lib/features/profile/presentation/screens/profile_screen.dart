
import 'package:flutter/material.dart';
import 'package:rumbo/features/safety/presentation/screens/emergency_contacts_screen.dart'
    as safety;

import '../../../../shared/components/section_title.dart';
import '../../../../shared/components/tag.dart';
import '../../../../shared/theme/rumbo_colors.dart';

import '../models/user_role.dart';
import '../../../auth/domain/entities/rumbo_user.dart';

class ProfileScreen extends StatefulWidget {
  final UserRole role;
  final VoidCallback onToggleRole;
  final VoidCallback onRequestOrganizer;
  final bool isOrganizerAuthorized;
  final RumboUser? user;
  final VoidCallback? onSignOut;

  const ProfileScreen({
    super.key,
    required this.role,
    required this.onToggleRole,
    required this.onRequestOrganizer,
    required this.isOrganizerAuthorized,
    this.user,
    this.onSignOut,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Set<String> interests = {
    'Senderismo',
    'Amanecer',
    'Aves',
  };

  void _openEmergencyContacts() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const safety.EmergencyContactsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final org = widget.role == UserRole.organizador;

    final userName = widget.user?.name.trim() ?? '';
    final avatarInitial = userName.isEmpty
        ? 'IN'
        : userName.substring(0, 1).toUpperCase();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
      children: [
        // Avatar del usuario.
        Center(
          child: CircleAvatar(
            radius: 42,
            backgroundColor: RumboColors.rosado,
            child: Text(
              avatarInitial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 24,
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Nombre del usuario.
        Center(
          child: Text(
            widget.user?.name ?? 'Vista previa',
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),

        // Rol seleccionado.
        Center(
          child: Text(
            org ? 'Organizador' : 'Participante',
            style: const TextStyle(
              color: RumboColors.musgo,
            ),
          ),
        ),

        const SectionTitle('Tus intereses'),

        // Intereses editables del prototipo.
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (widget.user?.interests ?? [
            'Senderismo',
            'Amanecer',
            'Ciclismo',
            'Aves',
            'Camping',
            'Fotografía',
            'Río',
          ]).map((interest) {
            return FilterChip(
              label: Text(interest),
              selected: widget.user == null
                  ? interests.contains(interest)
                  : widget.user!.interests.contains(interest),
              onSelected: widget.user != null
                  ? null
                  : (selected) {
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

        if (widget.user != null) ...[
          const SizedBox(height: 12),
          Text('@${widget.user!.username} · ${widget.user!.email}'),
          Text(
            'Edad: ${widget.user!.age} años · '
            'Teléfono: ${widget.user!.phone}',
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: widget.onSignOut,
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          ),
        ],

        // Seguridad personal.
        const SectionTitle('Seguridad personal'),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.health_and_safety_outlined),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Contactos de emergencia',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Registra y administra las personas de confianza '
                  'que estarán disponibles como tus contactos '
                  'de emergencia.',
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openEmergencyContacts,
                    icon: const Icon(Icons.contact_phone_outlined),
                    label: const Text('Administrar contactos'),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SectionTitle('Tu modo actual'),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tag(
                  org ? 'Organizador' : 'Participante',
                  sun: org,
                ),
                const SizedBox(height: 10),
                Text(
                  org
                      ? 'Publicas rutas, defines cupos '
                          'y apruebas solicitudes.'
                      : 'Te unes a planes de otros '
                          'y hablas con tu grupo.',
                ),
                const SizedBox(height: 14),
                if (widget.isOrganizerAuthorized)
                  OutlinedButton(
                    onPressed: widget.onToggleRole,
                    child: Text(
                      org
                          ? 'Ver como participante'
                          : 'Volver a vista organizador',
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: widget.onRequestOrganizer,
                    icon: const Icon(Icons.assignment_outlined),
                    label: const Text('Quiero ser organizador'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
