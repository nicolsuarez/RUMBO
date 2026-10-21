import 'package:flutter/material.dart';

import '../../../../shared/theme/rumbo_colors.dart';

import '../components/plan_card.dart';
import '../models/plan.dart';

class MyPlansScreen extends StatelessWidget {
  final List<Plan> plans;
  final Set<String> joined;
  final bool organizerMode;
  final String? activeRouteId;

  final ValueChanged<Plan> onOpen;
  final ValueChanged<Plan> onStartRoute;
  final VoidCallback onExplore;
  final Set<String> createdPlanIds;

  const MyPlansScreen({
    super.key,
    required this.plans,
    required this.joined,
    required this.organizerMode,
    required this.activeRouteId,
    required this.onOpen,
    required this.onStartRoute,
    required this.onExplore,
    required this.createdPlanIds,
  });

  @override
  Widget build(BuildContext context) {
    // Elegir planes según el rol.

    final items = organizerMode
        ? plans.where((plan) {
            return createdPlanIds.contains(plan.id) ||
                plan.id == 'pance' ||
                plan.id == 'bosque';
          }).toList()
        : plans.where((plan) {
            return joined.contains(plan.id);
          }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
      children: [
        Text(
          organizerMode ? 'Planes que organizo' : 'Mis planes',
          style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
        ),

        const SizedBox(height: 8),

        // Mensaje cuando no hay planes.
        if (items.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Icon(Icons.hiking, size: 44, color: RumboColors.musgo),

                  const SizedBox(height: 10),

                  const Text('Todavía no tienes planes guardados.'),

                  const SizedBox(height: 10),

                  OutlinedButton(
                    onPressed: onExplore,
                    child: const Text('Explorar planes'),
                  ),
                ],
              ),
            ),
          ),

        // Listado de actividades.
        ...items.map(
          (plan) => Column(
            children: [
              PlanCard(plan: plan, onTap: () => onOpen(plan)),

              // Solo el participante inicia recorridos.
              if (!organizerMode)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: OutlinedButton.icon(
                    onPressed: () => onStartRoute(plan),
                    icon: Icon(
                      activeRouteId == plan.id
                          ? Icons.play_arrow
                          : Icons.navigation_outlined,
                    ),
                    label: Text(
                      activeRouteId == plan.id
                          ? 'Continuar recorrido'
                          : 'Iniciar recorrido',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
