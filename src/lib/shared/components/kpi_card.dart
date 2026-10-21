import 'package:flutter/material.dart';

import '../theme/rumbo_colors.dart';

// componente que representa una tarjeta que usa un valor y un label
// para mostrar un KPI (indicador clave de rendimiento)
class KpiCard extends StatelessWidget {
  final String value;
  final String label;

  const KpiCard({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: RumboColors.musgo, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }
}
