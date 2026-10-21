import 'package:flutter/material.dart';

import '../../../../shared/components/tag.dart';
import '../../../../shared/theme/rumbo_colors.dart';
import '../models/plan.dart';
import 'hero_art.dart';

class PlanCard extends StatelessWidget {
  final Plan plan;
  final VoidCallback onTap;

  const PlanCard({super.key, required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 132,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 108, child: HeroArt(plan: plan, showText: false)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.titulo,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        plan.lugar,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: RumboColors.musgo,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 5,
                        children: [
                          Tag(plan.fecha.split(' · ').first),
                          Tag(
                            plan.dificultad,
                            warn: plan.dificultad == 'Exigente',
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: plan.cupos > 0
                                  ? (plan.van / plan.cupos).clamp(0.0, 1.0)
                                  : 0.0,
                              minHeight: 4,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${plan.van}/${plan.cupos}',
                            style: const TextStyle(
                              color: RumboColors.musgo,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            plan.precio == 'Gratis'
                                ? 'Sin costo'
                                : 'Desde ${plan.precio}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
