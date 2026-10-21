import 'package:flutter/material.dart';

import '../../../../shared/components/avatar_stack.dart';
import '../../../../shared/components/section_title.dart';
import '../../../../shared/theme/rumbo_colors.dart';

import '../../../plans/presentation/components/hero_plan_card.dart';
import '../../../plans/presentation/components/plan_card.dart';
import '../../../plans/presentation/models/plan.dart';

class HomeScreen extends StatefulWidget {
  final List<Plan> plans;
  final ValueChanged<Plan> onOpen;
  final VoidCallback onExplore;

  const HomeScreen({
    super.key,
    required this.plans,
    required this.onOpen,
    required this.onExplore,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String filter = 'Todo';

  @override
  Widget build(BuildContext context) {
    final visible = widget.plans.where((plan) {
      return filter == 'Todo' ||
          plan.tags.any(
            (tag) => tag.toLowerCase().contains(filter.toLowerCase()),
          );
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cali, Valle del Cauca',
                  style: TextStyle(
                    color: RumboColors.musgo,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Hola, Ines',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            CircleAvatar(
              backgroundColor: RumboColors.rosado,
              child: Text(
                'IN',
                style: TextStyle(
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

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Todo', 'Senderismo', 'Ciclismo', 'Aves', 'Camping', 'Río']
              .map((category) {
                return ChoiceChip(
                  label: Text(category),
                  selected: filter == category,
                  onSelected: (_) {
                    setState(() => filter = category);
                  },
                );
              })
              .toList(),
        ),

        const SectionTitle('Este fin de semana'),

        if (widget.plans.isNotEmpty)
          HeroPlanCard(
            plan: widget.plans.first,
            onTap: () => widget.onOpen(widget.plans.first),
          ),

        const SectionTitle('Cerca de ti'),

        ...visible
            .skip(1)
            .take(4)
            .map(
              (plan) => PlanCard(plan: plan, onTap: () => widget.onOpen(plan)),
            ),

        const SectionTitle('Gente que va a lo mismo que tú'),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const AvatarStack(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '9 personas con tus mismos '
                        'intereses tienen plan este sábado.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: widget.onExplore,
                  child: const Text('Ver sus planes'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
