import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../plans/domain/entities/plan_entity.dart';
import '../../../plans/presentation/bloc/plans_bloc.dart';
import '../../../plans/presentation/screens/plan_detail_screen.dart';
import '../../domain/entities/enrollment_entity.dart';
import '../bloc/enrollments_bloc.dart';

/// US-06 y US-07: lista persistente de las inscripciones del usuario.
class MyEnrollmentsScreen extends StatelessWidget {
  const MyEnrollmentsScreen({super.key, required this.onExplore});
  final VoidCallback onExplore;

  Future<void> _cancel(BuildContext context, EnrollmentEntity item) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar inscripción'),
        content: Text('¿Quieres cancelar tu participación en '
            '${item.planTitle ?? 'este plan'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (yes == true && context.mounted) {
      context.read<EnrollmentsBloc>().add(EnrollmentsCancelRequested(item.planId));
    }
  }

  void _open(BuildContext context, EnrollmentEntity item) {
    final plans = context.read<PlansBloc>().state;
    PlanEntity? found;
    for (final plan in [...plans.published, ...plans.mine]) {
      if (plan.id == item.planId) {
        found = plan;
        break;
      }
    }
    if (found == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Este plan ya no está disponible en el listado de actividades.'),
      ));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => PlanDetailScreen.fromEntity(plan: found!),
    ));
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<EnrollmentsBloc, EnrollmentsState>(
    builder: (context, state) {
      final items = state.mine;
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
        children: [
          const Text('Mis planes',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('Tus inscripciones guardadas en Supabase y su estado.'),
          const SizedBox(height: 10),
          Row(children: [
            Text('${items.length} inscripciones'),
            const Spacer(),
            TextButton.icon(
              onPressed: state.loading
                  ? null
                  : () => context.read<EnrollmentsBloc>().add(
                        const EnrollmentsLoadRequested()),
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
          ]),
          if (state.loading) const LinearProgressIndicator(),
          if (state.error != null) ...[
            const SizedBox(height: 10),
            Text('Error: ${state.error}',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (items.isEmpty && !state.loading) ...[
            const SizedBox(height: 24),
            const Icon(Icons.hiking_outlined, size: 55),
            const SizedBox(height: 12),
            const Center(child: Text('Aún no tienes inscripciones.')),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onExplore,
              child: const Text('Explorar planes'),
            ),
          ],
          for (final item in items) ...[
            const SizedBox(height: 10),
            Card(
              child: Column(children: [
                ListTile(
                  title: Text(item.planTitle ?? 'Plan'),
                  subtitle: Text([
                    if (item.planPlace != null) item.planPlace!,
                    if (item.planStartsAt != null)
                      _date(item.planStartsAt!),
                  ].join(' · ')),
                  trailing: Chip(label: Text(_label(item.status))),
                  onTap: () => _open(context, item),
                ),
                if (item.isActive)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        onPressed: state.busyPlanId != null
                            ? null
                            : () => _cancel(context, item),
                        child: Text(item.status == EnrollmentStatus.pending
                            ? 'Retirar solicitud'
                            : 'Cancelar inscripción'),
                      ),
                    ),
                  ),
              ]),
            ),
          ],
        ],
      );
    },
  );
}

String _label(EnrollmentStatus status) => switch (status) {
  EnrollmentStatus.pending => 'Pendiente',
  EnrollmentStatus.confirmed => 'Confirmada',
  EnrollmentStatus.cancelled => 'Cancelada',
  EnrollmentStatus.rejected => 'Rechazada',
};

String _date(DateTime value) {
  final d = value.toLocal();
  return '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}
