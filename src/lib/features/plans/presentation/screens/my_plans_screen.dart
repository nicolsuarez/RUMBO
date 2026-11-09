import 'package:flutter/material.dart';

import '../../../../shared/theme/rumbo_colors.dart';
import '../components/organizer_plans_content.dart';
import '../components/plan_card.dart';
import '../models/plan.dart';

/// Única pantalla «Mis planes».
///
/// Organizador: PlanEntity + PlansBloc + Supabase.
/// Participante: flujo temporal de la maqueta; su migración corresponde a
/// Enrollments y Routes. Mantener la firma evita romper esas features.
class MyPlansScreen extends StatelessWidget {
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
  }) : onCreate = null;

  /// Entrada nueva para organizadores, sin listas ni IDs simulados.
  const MyPlansScreen.organizer({super.key, required this.onCreate})
    : plans = const <Plan>[],
      joined = const <String>{},
      organizerMode = true,
      activeRouteId = null,
      onOpen = null,
      onStartRoute = null,
      onExplore = null,
      createdPlanIds = const <String>{};

  // Parámetros legados utilizados únicamente por los participantes.
  final List<Plan> plans;
  final Set<String> joined;
  final bool organizerMode;
  final String? activeRouteId;
  final ValueChanged<Plan>? onOpen;
  final ValueChanged<Plan>? onStartRoute;
  final VoidCallback? onExplore;
  final Set<String> createdPlanIds;

  // Navegación del organizador hacia la pestaña Crear de RumboShell.
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    if (organizerMode) {
      return OrganizerPlansContent(onCreate: onCreate);
    }
    return _ParticipantPlansView(
      plans: plans,
      joined: joined,
      activeRouteId: activeRouteId,
      onOpen: onOpen!,
      onStartRoute: onStartRoute!,
      onExplore: onExplore!,
    );
  }
}

class _ParticipantPlansView extends StatelessWidget {
  const _ParticipantPlansView({
    required this.plans,
    required this.joined,
    required this.activeRouteId,
    required this.onOpen,
    required this.onStartRoute,
    required this.onExplore,
  });

  final List<Plan> plans;
  final Set<String> joined;
  final String? activeRouteId;
  final ValueChanged<Plan> onOpen;
  final ValueChanged<Plan> onStartRoute;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final items = plans.where((plan) => joined.contains(plan.id)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
      children: [
        const Text(
          'Mis planes',
          style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text(
          'Inscripciones de prueba. Se conectarán a Enrollments.',
          style: TextStyle(color: RumboColors.musgo, fontSize: 12),
        ),
        const SizedBox(height: 8),
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
        for (final plan in items)
          Column(
            children: [
              PlanCard(plan: plan, onTap: () => onOpen(plan)),
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
      ],
    );
  }
}
