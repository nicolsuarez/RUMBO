import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/components/kpi_card.dart';
import '../../../../shared/components/section_title.dart';
import '../../../../shared/theme/rumbo_colors.dart';
import '../../../plans/domain/entities/plan_entity.dart';
import '../../../plans/presentation/bloc/plans_bloc.dart';
import '../../../plans/presentation/components/plan_card.dart';
import '../../../plans/presentation/screens/plan_detail_screen.dart';

/// Panel visual del organizador. Ya no depende de IDs de planes simulados.
class OrganizerPanel extends StatelessWidget {
  const OrganizerPanel({
    super.key,
    required this.onCreate,
    this.onMyPlans,
    this.onOpen,
  });

  final VoidCallback onCreate;
  final VoidCallback? onMyPlans;
  final ValueChanged<PlanEntity>? onOpen;

  void _openPlan(BuildContext context, PlanEntity plan) {
    if (onOpen != null) {
      onOpen!(plan);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => PlanDetailScreen.fromEntity(plan: plan, organizerOwnPlan: true)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlansBloc, PlansState>(
      builder: (context, state) {
        final published = state.mine
            .where((plan) => plan.status == PlanStatus.published)
            .toList();
        final drafts = state.mine
            .where((plan) => plan.status == PlanStatus.draft)
            .toList();
        final finished = state.mine
            .where((plan) => plan.status == PlanStatus.finished)
            .length;
        final activityNames = <int, String>{
          for (final activity in state.activities) activity.id: activity.name,
        };

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
            Row(
              children: [
                Expanded(
                  child: KpiCard(
                    value: '${published.length}',
                    label: 'publicados',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: KpiCard(value: '${drafts.length}', label: 'borradores'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: KpiCard(value: '$finished', label: 'finalizados'),
                ),
              ],
            ),
            if (state.loading) ...[
              const SizedBox(height: 14),
              const LinearProgressIndicator(),
            ],
            if (state.error != null) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('No pudimos cargar tus planes.'),
                      const SizedBox(height: 6),
                      Text(
                        state.error!,
                        style: const TextStyle(color: RumboColors.alerta),
                      ),
                      TextButton.icon(
                        onPressed: () => context.read<PlansBloc>().add(
                              const PlansRefreshRequested(),
                            ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SectionTitle('Solicitudes por aprobar'),
            // Esta sección depende de Enrollments; no se inventan solicitudes.
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Row(
                  children: [
                    Icon(Icons.mark_email_unread_outlined,
                        color: RumboColors.monte2),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Aquí aparecerán las solicitudes cuando se '
                        'integre la funcionalidad de inscripciones.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SectionTitle('Tus planes publicados'),
            if (published.isEmpty && !state.loading && state.error == null)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('Todavía no has publicado ningún plan.'),
                ),
              ),
            ...published.take(5).map(
              (plan) => PlanCard.fromEntity(
                plan: plan,
                activityName: activityNames[plan.activityTypeId],
                onTap: () => _openPlan(context, plan),
              ),
            ),
            if (drafts.isNotEmpty) ...[
              const SectionTitle('Borradores'),
              ...drafts.take(3).map(
                    (plan) => PlanCard.fromEntity(
                      plan: plan,
                      activityName: activityNames[plan.activityTypeId],
                      onTap: () => onMyPlans != null
                          ? onMyPlans!()
                          : _openPlan(context, plan),
                    ),
                  ),
            ],
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
            if (onMyPlans != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onMyPlans,
                icon: const Icon(Icons.list_alt_outlined),
                label: const Text('Gestionar todos mis planes'),
              ),
            ],
          ],
        );
      },
    );
  }
}
