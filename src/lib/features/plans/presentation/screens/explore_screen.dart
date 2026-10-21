import 'package:flutter/material.dart';

import '../../../../shared/painters/map_painter.dart';
import '../../../../shared/theme/rumbo_colors.dart';

import '../components/plan_card.dart';
import '../models/plan.dart';

class ExploreScreen extends StatefulWidget {
  final List<Plan> plans;
  final ValueChanged<Plan> onOpen;

  const ExploreScreen({super.key, required this.plans, required this.onOpen});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  bool mapMode = false;

  final Set<String> filters = {'Cualquier día'};

  @override
  Widget build(BuildContext context) {
    final filteredPlans = widget.plans.where((plan) {
      if (filters.contains('Suave') && plan.dificultad != 'Suave') {
        return false;
      }

      if (filters.contains('Exigente') && plan.dificultad != 'Exigente') {
        return false;
      }

      if (filters.contains('Con cupos') && plan.van >= plan.cupos) {
        return false;
      }

      if (filters.contains('Gratis') && plan.precio != 'Gratis') {
        return false;
      }

      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
      children: [
        const Text(
          'Explorar',
          style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
        ),

        const SizedBox(height: 14),

        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              label: Text('Lista'),
              icon: Icon(Icons.list),
            ),
            ButtonSegment(
              value: true,
              label: Text('Mapa'),
              icon: Icon(Icons.map_outlined),
            ),
          ],
          selected: {mapMode},
          onSelectionChanged: (selection) {
            setState(() {
              mapMode = selection.first;
            });
          },
        ),

        if (mapMode) ...[
          const SizedBox(height: 14),
          const DemoMap(height: 205),
        ],

        const SizedBox(height: 14),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              ['Cualquier día', 'Suave', 'Exigente', 'Con cupos', 'Gratis'].map(
                (filter) {
                  return FilterChip(
                    label: Text(filter),
                    selected: filters.contains(filter),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          filters.add(filter);
                        } else {
                          filters.remove(filter);
                        }
                      });
                    },
                  );
                },
              ).toList(),
        ),

        const SizedBox(height: 16),

        Text(
          '${filteredPlans.length} planes encontrados',
          style: const TextStyle(
            color: RumboColors.musgo,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 10),

        ...filteredPlans.map(
          (plan) => PlanCard(plan: plan, onTap: () => widget.onOpen(plan)),
        ),
      ],
    );
  }
}
