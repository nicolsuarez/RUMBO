import 'package:flutter/material.dart';

/// Catálogo provisional: se migrará a la tabla ETIQUETA/INTERES según el modelo final.
const registrationInterests = <String>[
  'Senderismo',
  'Avistamiento de aves',
  'Ciclismo',
  'Camping',
  'Fotografía',
  'Amaneceres',
  'Atardeceres',
  'Ríos',
  'Cascadas',
  'Montañismo',
  'Trekking',
  'Naturaleza',
  'Ecoturismo',
  'Trail running',
  'Caminatas ecológicas',
  'Observación de fauna',
  'Flora',
  'Paisajismo',
  'Picnic',
  'Astronomía',
  'Aventura',
  'Viajes',
  'Bienestar',
  'Actividades en grupo',
];

class RegisterInterestsPage extends StatelessWidget {
  const RegisterInterestsPage({
    super.key,
    required this.selected,
    required this.onChanged,
  });
  final Set<String> selected;
  final void Function(String interest, bool selected) onChanged;

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      Text(
        '¿Qué te gusta hacer?',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      const Text('Elige al menos un interés. Puedes seleccionar varios.'),
      const SizedBox(height: 18),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: registrationInterests
            .map(
              (interest) => FilterChip(
                label: Text(interest),
                selected: selected.contains(interest),
                onSelected: (value) => onChanged(interest, value),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 16),
      Text('${selected.length} intereses seleccionados'),
    ],
  );
}
