import 'package:flutter/material.dart';

import '../../../../shared/components/kpi_card.dart';
import '../../../../shared/components/section_title.dart';
import '../../../../shared/theme/rumbo_colors.dart';

import '../../../enrollments/presentation/components/approval_card.dart';
import '../../../plans/presentation/components/plan_card.dart';
import '../../../plans/presentation/models/plan.dart';

class OrganizerPanel extends StatelessWidget {
  final List<Plan> plans;
  final Set<String> createdPlanIds;
  final ValueChanged<Plan> onOpen;
  final VoidCallback onCreate;

  const OrganizerPanel({
    super.key,
    required this.plans,
    required this.createdPlanIds,
    required this.onOpen,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final own = plans.where((plan) {
      return plan.id == 'pance' ||
          plan.id == 'bosque' ||
          createdPlanIds.contains(plan.id);
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
      children: [
        const Text(
          'Modo organizador',
          style: TextStyle(
            color: RumboColors.musgo,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Text(
          'Tu panel',
          style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),

        // Indicadores generales.
        Row(
          children: [
            Expanded(
              child: KpiCard(value: '${own.length}', label: 'planes activos'),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: KpiCard(value: '17', label: 'personas inscritas'),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: KpiCard(value: '3', label: 'solicitudes'),
            ),
          ],
        ),

        const SectionTitle('Solicitudes por aprobar'),

        ...const [
          (
            'Laura Sofía Armero',
            'Charco de Pance',
            'Va con dos amigas, primera vez en el grupo',
            'LS',
          ),
          (
            'Mateo Jaramillo',
            'Camping en el Topacio',
            'Tiene carpa propia y experiencia en camping',
            'MJ',
          ),
          (
            'Valeria Ospina',
            'Charco de Pance',
            'Pregunta si puede llevar a su hijo de 9 años',
            'VO',
          ),
        ].map(
          (request) => ApprovalCard(
            name: request.$1,
            plan: request.$2,
            note: request.$3,
            initials: request.$4,
          ),
        ),

        const SectionTitle('Tus planes publicados'),

        if (own.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text('Todavía no has publicado ningún plan.'),
            ),
          ),

        ...own.map((plan) => PlanCard(plan: plan, onTap: () => onOpen(plan))),

        const SizedBox(height: 8),

        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add),
          label: const Text('Crear un plan nuevo'),
          style: FilledButton.styleFrom(
            backgroundColor: RumboColors.guayacan,
            foregroundColor: RumboColors.tinta,
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      ],
    );
  }
}
