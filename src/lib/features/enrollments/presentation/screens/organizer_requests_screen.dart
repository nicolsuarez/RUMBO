import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../plans/domain/entities/plan_entity.dart';
import '../../domain/entities/enrollment_entity.dart';
import '../bloc/enrollments_bloc.dart';

/// Flujo adicional para planes privados: aprobación con verificación de cupos.
class OrganizerRequestsScreen extends StatefulWidget {
  const OrganizerRequestsScreen({super.key, required this.plan});
  final PlanEntity plan;

  @override
  State<OrganizerRequestsScreen> createState() => _OrganizerRequestsScreenState();
}

class _OrganizerRequestsScreenState extends State<OrganizerRequestsScreen> {
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => context.read<EnrollmentsBloc>().add(
        EnrollmentsPlanRequested(widget.plan.id, includeRequests: true),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Solicitudes del plan')),
    body: BlocBuilder<EnrollmentsBloc, EnrollmentsState>(
      builder: (context, state) {
        final pending = state.pendingByPlan[widget.plan.id] ?? <EnrollmentEntity>[];
        final availability = state.availabilityByPlan[widget.plan.id];
        final working = state.busyPlanId != null;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(widget.plan.title,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(availability == null
                ? 'Consultando cupos...'
                : '${availability.occupied} de ${availability.capacity} cupos ocupados'),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: state.loadingPlanId != null ? null : _reload,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar solicitudes'),
            ),
            if (state.loadingPlanId == widget.plan.id)
              const LinearProgressIndicator(),
            if (pending.isEmpty && state.loadingPlanId != widget.plan.id)
              const Padding(
                padding: EdgeInsets.all(18),
                child: Text('No tienes solicitudes pendientes.'),
              ),
            for (final item in pending)
              Card(child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Solicitud de participante ${item.userId.substring(0, 8)}'),
                    const SizedBox(height: 6),
                    Text('Recibida: ${item.enrolledAt.toLocal()}'),
                    const SizedBox(height: 8),
                    Wrap(spacing: 10, children: [
                      FilledButton(
                        onPressed: working || availability?.isFull == true
                            ? null
                            : () => context.read<EnrollmentsBloc>().add(
                                EnrollmentsResolveRequested(
                                  widget.plan.id, item.id, approve: true)),
                        child: const Text('Aprobar'),
                      ),
                      OutlinedButton(
                        onPressed: working
                            ? null
                            : () => context.read<EnrollmentsBloc>().add(
                                EnrollmentsResolveRequested(
                                  widget.plan.id, item.id, approve: false)),
                        child: const Text('Rechazar'),
                      ),
                    ]),
                  ],
                ),
              )),
          ],
        );
      },
    ),
  );
}
