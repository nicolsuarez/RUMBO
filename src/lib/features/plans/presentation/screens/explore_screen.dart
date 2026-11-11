import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/painters/map_painter.dart';
import '../../../../shared/theme/rumbo_colors.dart';
import '../../domain/entities/plan_entity.dart';
import '../bloc/plans_bloc.dart';
import '../components/plan_card.dart';
import 'plan_detail_screen.dart';

/// Explora planes publicados desde PlansBloc, sin listas simuladas.
/// Conserva el diseño visual de ExploreScreen (lista, mapa y filtros).
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  bool mapMode = false;
  bool weekendOnly = false;
  bool freeOnly = false;
  final Set<PlanDifficulty> difficultyFilters = <PlanDifficulty>{};

  bool _matches(PlanEntity plan) {
    if (difficultyFilters.isNotEmpty &&
        !difficultyFilters.contains(plan.difficulty)) {
      return false;
    }
    if (freeOnly && plan.budgetPerPerson != 0) return false;
    if (weekendOnly && !_isThisWeekend(plan.startsAt)) return false;
    return true;
  }

  bool _isThisWeekend(DateTime? date) {
    if (date == null) return false;
    final today = DateTime.now();
    // Si hoy es domingo, corresponde al fin de semana que termina hoy.
    final daysToSaturday = today.weekday == DateTime.sunday
        ? -1
        : DateTime.saturday - today.weekday;
    final saturday = DateTime(
      today.year,
      today.month,
      today.day + daysToSaturday,
    );
    final monday = DateTime(saturday.year, saturday.month, saturday.day + 2);
    final local = date.toLocal();
    return !local.isBefore(saturday) && local.isBefore(monday);
  }

  Future<void> _refresh() async {
    final bloc = context.read<PlansBloc>();
    bloc.add(const PlansRefreshRequested());
    // Esperar el resultado real del BLoC antes de cerrar el indicador.
    await bloc.stream.firstWhere((state) => !state.loading);
  }

  void _openPlan(PlanEntity plan) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlanDetailScreen.fromEntity(plan: plan),
      ),
    );
  }

  Widget _difficultyChip(String label, PlanDifficulty difficulty) {
    return FilterChip(
      label: Text(label),
      selected: difficultyFilters.contains(difficulty),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            difficultyFilters.add(difficulty);
          } else {
            difficultyFilters.remove(difficulty);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlansBloc, PlansState>(
      builder: (context, state) {
        final activityNames = {
          for (final activity in state.activities) activity.id: activity.name,
        };
        final filteredPlans = state.published.where(_matches).toList();

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
            children: [
              const Text(
                'Explorar',
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Lista'),
                    icon: Icon(Icons.list),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Mapa'),
                    icon: Icon(Icons.map_outlined),
                  ),
                ],
                selected: {mapMode},
                onSelectionChanged: (selection) {
                  setState(() => mapMode = selection.first);
                },
              ),
              if (mapMode) ...[
                const SizedBox(height: 14),
                const DemoMap(height: 205),
                const SizedBox(height: 6),
                const Text(
                  'Mapa ilustrativo. No muestra la ubicación real de los planes.',
                  style: TextStyle(fontSize: 12, color: RumboColors.musgo),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Cualquier día'),
                    selected: !weekendOnly,
                    onSelected: (_) => setState(() => weekendOnly = false),
                  ),
                  FilterChip(
                    label: const Text('Este fin de semana'),
                    selected: weekendOnly,
                    onSelected: (selected) {
                      setState(() => weekendOnly = selected);
                    },
                  ),
                  _difficultyChip('Suave', PlanDifficulty.easy),
                  _difficultyChip('Media', PlanDifficulty.medium),
                  _difficultyChip('Exigente', PlanDifficulty.hard),
                  const Tooltip(
                    message: 'Disponible cuando se integren las inscripciones.',
                    child: FilterChip(
                      label: Text('Con cupos'),
                      selected: false,
                      onSelected: null,
                    ),
                  ),
                  FilterChip(
                    label: const Text('Gratis'),
                    selected: freeOnly,
                    onSelected: (selected) {
                      setState(() => freeOnly = selected);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (state.loading) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 10),
              ],
              if (state.error != null) ...[
                Text(
                  'No se pudieron actualizar los planes: ${state.error}',
                  style: const TextStyle(color: Colors.red),
                ),
                TextButton.icon(
                  onPressed: () => context.read<PlansBloc>().add(
                    const PlansRefreshRequested(),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
              Text(
                '${filteredPlans.length} planes encontrados',
                style: const TextStyle(
                  color: RumboColors.musgo,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              if (!state.loading && filteredPlans.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    state.published.isEmpty
                        ? 'Aún no hay planes publicados con fechas próximas.'
                        : 'No hay planes que cumplan estos filtros.',
                  ),
                ),
              ...filteredPlans.map(
                (plan) => PlanCard.fromEntity(
                  plan: plan,
                  activityName: activityNames[plan.activityTypeId],
                  onTap: () => _openPlan(plan),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
