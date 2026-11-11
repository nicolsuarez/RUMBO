import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/components/kpi_card.dart';
import '../../../../shared/theme/rumbo_colors.dart';
import '../../domain/entities/plan_entity.dart';
import '../bloc/plans_bloc.dart';
import 'plan_card.dart';
import '../screens/plan_detail_screen.dart';
import '../screens/plan_editor_page.dart';

/// Contenido de gestión del organizador. No es otra pantalla ni otra fuente
/// de datos: consume el mismo PlansBloc que Home y Explorar.
enum _OrganizerFilter { all, published, drafts, cancelled, finished }

extension _OrganizerFilterUi on _OrganizerFilter {
  String get label => switch (this) {
    _OrganizerFilter.all => 'Todos',
    _OrganizerFilter.published => 'Publicados',
    _OrganizerFilter.drafts => 'Borradores',
    _OrganizerFilter.cancelled => 'Cancelados',
    _OrganizerFilter.finished => 'Finalizados',
  };

  bool includes(PlanStatus status) => switch (this) {
    _OrganizerFilter.all => true,
    _OrganizerFilter.published => status == PlanStatus.published,
    _OrganizerFilter.drafts => status == PlanStatus.draft,
    _OrganizerFilter.cancelled => status == PlanStatus.cancelled,
    _OrganizerFilter.finished => status == PlanStatus.finished,
  };
}

class OrganizerPlansContent extends StatefulWidget {
  const OrganizerPlansContent({this.onCreate});

  final VoidCallback? onCreate;

  @override
  State<OrganizerPlansContent> createState() => _OrganizerPlansContentState();
}

class _OrganizerPlansContentState extends State<OrganizerPlansContent> {
  _OrganizerFilter _filter = _OrganizerFilter.all;
  bool _pendingAction = false;

  void _openPlan(PlanEntity plan) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            PlanDetailScreen.fromEntity(plan: plan, organizerOwnPlan: true),
      ),
    );
  }

  void _editPlan(PlanEntity plan) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Editar plan')),
          body: PlanEditorPage(initial: plan),
        ),
      ),
    );
  }

  void _createPlan() {
    if (widget.onCreate != null) {
      widget.onCreate!();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Crear plan')),
          body: const PlanEditorPage(),
        ),
      ),
    );
  }

  Future<void> _confirmAction({
    required String title,
    required String explanation,
    required PlansEvent event,
    required String confirmationLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(explanation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmationLabel),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    _pendingAction = true;
    context.read<PlansBloc>().add(event);
  }

  void _notifyActionResult(BuildContext context, PlansState state) {
    if (!_pendingAction) return;
    _pendingAction = false;
    final message = state.error ?? state.message;
    if (message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlansBloc, PlansState>(
      listenWhen: (previous, current) =>
          previous.saving &&
          !current.saving &&
          (current.error != null || current.message != null),
      listener: _notifyActionResult,
      builder: (context, state) {
        final mine = List<PlanEntity>.of(state.mine)
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        final visible = mine.where((plan) => _filter.includes(plan.status));
        final published = mine
            .where((plan) => plan.status == PlanStatus.published)
            .length;
        final drafts = mine
            .where((plan) => plan.status == PlanStatus.draft)
            .length;
        final finished = mine
            .where((plan) => plan.status == PlanStatus.finished)
            .length;
        final activityNames = <int, String>{
          for (final activity in state.activities) activity.id: activity.name,
        };

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Planes que organizo',
                    style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar planes',
                  onPressed: state.loading || state.saving
                      ? null
                      : () => context.read<PlansBloc>().add(
                          const PlansRefreshRequested(),
                        ),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Administra tus actividades desde un solo lugar.',
              style: TextStyle(color: RumboColors.musgo),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: KpiCard(value: '$published', label: 'publicados'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: KpiCard(value: '$drafts', label: 'borradores'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: KpiCard(value: '$finished', label: 'finalizados'),
                ),
              ],
            ),
            if (state.loading || state.saving) ...[
              const SizedBox(height: 12),
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
                      const Text('No se pudo completar la operación.'),
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
                        label: const Text('Reintentar consulta'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final filter in _OrganizerFilter.values)
                  ChoiceChip(
                    label: Text(filter.label),
                    selected: _filter == filter,
                    onSelected: (_) => setState(() => _filter = filter),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${visible.length} ${visible.length == 1 ? 'plan' : 'planes'}',
              style: const TextStyle(
                color: RumboColors.musgo,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            if (!state.loading && mine.isEmpty && state.error == null)
              _EmptyPlansCard(
                message: 'Todavía no has creado ningún plan.',
                onCreate: _createPlan,
              )
            else if (!state.loading && visible.isEmpty && state.error == null)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('No tienes planes con este estado.'),
                ),
              ),
            for (final plan in visible) ...[
              PlanCard.fromEntity(
                plan: plan,
                activityName: activityNames[plan.activityTypeId],
                onTap: () => _openPlan(plan),
              ),
              _managementActions(plan, disabled: state.saving || state.loading),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: state.saving ? null : _createPlan,
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
      },
    );
  }

  Widget _managementActions(PlanEntity plan, {required bool disabled}) {
    final canEdit =
        plan.status == PlanStatus.draft || plan.status == PlanStatus.published;
    final canFinish =
        plan.status == PlanStatus.published &&
        plan.startsAt != null &&
        !plan.startsAt!.isAfter(DateTime.now());
    if (!canEdit) return const SizedBox(height: 10);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 2,
        children: [
          OutlinedButton.icon(
            onPressed: disabled ? null : () => _editPlan(plan),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Editar'),
          ),
          if (plan.status == PlanStatus.draft)
            TextButton.icon(
              onPressed: disabled
                  ? null
                  : () => _confirmAction(
                      title: 'Eliminar borrador',
                      explanation:
                          '¿Eliminar definitivamente «${plan.title}»? '
                          'Esta acción no se puede deshacer.',
                      event: PlansDeleteDraftRequested(plan.id),
                      confirmationLabel: 'Eliminar',
                    ),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Eliminar'),
            ),
          if (plan.status == PlanStatus.published)
            TextButton.icon(
              onPressed: disabled
                  ? null
                  : () => _confirmAction(
                      title: 'Cancelar plan',
                      explanation:
                          '¿Cancelar «${plan.title}»? No podrás restaurarlo.',
                      event: PlansCancelRequested(plan.id),
                      confirmationLabel: 'Cancelar plan',
                    ),
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('Cancelar'),
            ),
          if (canFinish)
            TextButton.icon(
              onPressed: disabled
                  ? null
                  : () => _confirmAction(
                      title: 'Finalizar plan',
                      explanation:
                          '¿Confirmas que la actividad «${plan.title}» terminó?',
                      event: PlansFinishRequested(plan.id),
                      confirmationLabel: 'Finalizar',
                    ),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Finalizar'),
            ),
        ],
      ),
    );
  }
}

class _EmptyPlansCard extends StatelessWidget {
  const _EmptyPlansCard({required this.message, required this.onCreate});

  final String message;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          const Icon(Icons.hiking, size: 44, color: RumboColors.musgo),
          const SizedBox(height: 10),
          Text(message),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onCreate,
            child: const Text('Crear mi primer plan'),
          ),
        ],
      ),
    ),
  );
}
