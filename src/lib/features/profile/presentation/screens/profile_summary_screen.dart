import 'package:flutter/material.dart';
import '../../../auth/domain/entities/rumbo_user.dart';

/// Resumen que se presenta una sola vez, tras completar el registro.
/// Recibe los datos reales desde AuthBloc, no desde el formulario local.
class ProfileSummaryScreen extends StatelessWidget {
  const ProfileSummaryScreen({
    super.key,
    required this.user,
    required this.onContinue,
  });

  final RumboUser user;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro completado'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Icon(Icons.check_circle_outline, size: 58),
                const SizedBox(height: 16),
                Text('¡Bienvenido a RUMBO!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Text('Tu cuenta ha sido creada. Este es el resumen de tu perfil:',
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                _ProfileLine(label: 'Nombre completo', value: user.name),
                _ProfileLine(label: 'Nombre de usuario', value: '@${user.username}'),
                _ProfileLine(label: 'Correo', value: user.email),
                _ProfileLine(label: 'Teléfono', value: user.phone),
                _ProfileLine(label: 'Edad', value: '${user.age} años'),
                _ProfileLine(label: 'Rol', value: user.isOrganizer ? 'Organizador' : 'Participante'),
                const SizedBox(height: 16),
                Text('Tus intereses', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: user.interests
                      .map((name) => Chip(label: Text(name)))
                      .toList(),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: onContinue,
                  child: const Text('Comenzar a explorar RUMBO'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 2),
            Text(value),
          ],
        ),
      );
}
