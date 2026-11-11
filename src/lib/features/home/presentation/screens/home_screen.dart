import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/components/section_title.dart';
import '../../../../shared/theme/rumbo_colors.dart';
import '../../../plans/domain/entities/activity_type.dart';
import '../../../plans/domain/entities/plan_entity.dart';
import '../../../plans/presentation/bloc/plans_bloc.dart';
import '../../../plans/presentation/components/hero_plan_card.dart';
import '../../../plans/presentation/components/plan_card.dart';
import '../../../plans/presentation/screens/plan_detail_screen.dart';

/// Portada del participante. Conserva el estilo original, pero todos los
/// planes y tipos de actividad proceden de PlansBloc (Supabase).
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.userName,
    required this.onExplore,
    this.onOpen,
  });

  final String userName;
  final VoidCallback onExplore;
  final ValueChanged<PlanEntity>? onOpen;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Null significa "Todo". El ID corresponde al catálogo real de Supabase.
  int? selectedActivityId;

  void _openPlan(PlanEntity plan) {
    if (widget.onOpen != null) {
      widget.onOpen!(plan);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PlanDetailScreen.fromEntity(plan: plan)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nameParts = widget.userName.trim().split(RegExp(r'\s+'));
    final initials = nameParts
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return BlocBuilder<PlansBloc, PlansState>(
      builder: (context, state) {
        final activityNames = <int, String>{
          for (final activity in state.activities) activity.id: activity.name,
        };
        final selectedId = activityNames.containsKey(selectedActivityId)
            ? selectedActivityId
            : null;
        final filtered = state.published
            .where((plan) =>
                selectedId == null || plan.activityTypeId == selectedId)
            .toList()
          ..sort((a, b) => _compareDates(a.startsAt, b.startsAt));

        final now = DateTime.now();
        PlanEntity? featured;
        for (final plan in filtered) {
          if (_isNextWeekend(plan.startsAt, now)) {
            featured = plan;
            break;
          }
        }
        final featuredId = featured?.id;
        final remaining = filtered
            .where((plan) => plan.id != featuredId)
            .take(4)
            .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cali, Valle del Cauca',
                        style: TextStyle(
                          color: RumboColors.musgo,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hola, ${widget.userName}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: RumboColors.rosado,
                  child: Text(
                    initials.isEmpty ? '?' : initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Card(
              child: ListTile(
                onTap: widget.onExplore,
                leading: const Icon(Icons.search),
                title: const Text(
                  'Buscar ruta, cerro o actividad',
                  style: TextStyle(color: RumboColors.musgo),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _ActivityFilters(
              activities: state.activities,
              selectedActivityId: selectedId,
              onSelected: (value) {
                setState(() => selectedActivityId = value);
              },
            ),
            if (state.loading) ...[
              const SizedBox(height: 14),
              const LinearProgressIndicator(),
            ],
            if (state.error != null) ...[
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('No pudimos cargar los planes.'),
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
            const SectionTitle('Este fin de semana'),
            if (featured != null)
              HeroPlanCard.fromEntity(
                plan: featured,
                onTap: () => _openPlan(featured!),
              )
            else if (!state.loading && state.error == null)
              const _EmptySection(
                message: 'No hay actividades programadas para este fin de semana.',
              ),
            const SectionTitle('Próximos planes'),
            // Sin GPS no afirmamos que estos planes estén "cerca de ti".
            if (remaining.isEmpty && !state.loading && state.error == null)
              const _EmptySection(
                message: 'No hay más planes disponibles con este filtro.',
              ),
            ...remaining.map(
              (plan) => PlanCard.fromEntity(
                plan: plan,
                activityName: activityNames[plan.activityTypeId],
                onTap: () => _openPlan(plan),
              ),
            ),
            const SectionTitle('Gente que va a lo mismo que tú'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.groups_outlined,
                          size: 34,
                          color: RumboColors.monte2,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Descubre planes de personas que disfrutan las '
                            'actividades al aire libre. Las coincidencias con '
                            'tus intereses llegarán en una próxima integración.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton(
                      onPressed: widget.onExplore,
                      child: const Text('Explorar planes'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActivityFilters extends StatelessWidget {
  const _ActivityFilters({
    required this.activities,
    required this.selectedActivityId,
    required this.onSelected,
  });

  final List<ActivityType> activities;
  final int? selectedActivityId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Todo'),
          selected: selectedActivityId == null,
          onSelected: (_) => onSelected(null),
        ),
        ...activities.map(
          (activity) => ChoiceChip(
            label: Text(activity.name),
            selected: selectedActivityId == activity.id,
            onSelected: (_) => onSelected(activity.id),
          ),
        ),
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          message,
          style: const TextStyle(color: RumboColors.musgo),
        ),
      ),
    );
  }
}

int _compareDates(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

bool _isNextWeekend(DateTime? start, DateTime now) {
  if (start == null) return false;
  final date = start.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  // Si hoy es domingo, todavía pertenece al fin de semana actual.
  final daysToSaturday = today.weekday == DateTime.sunday
      ? -1
      : (DateTime.saturday - today.weekday + 7) % 7;
  final saturday = today.add(Duration(days: daysToSaturday));
  final monday = saturday.add(const Duration(days: 2));
  return !date.isBefore(saturday) && date.isBefore(monday);
}
