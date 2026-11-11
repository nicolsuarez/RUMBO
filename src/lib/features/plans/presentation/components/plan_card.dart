import 'package:flutter/material.dart';

import '../../../../shared/components/tag.dart';
import '../../../../shared/theme/rumbo_colors.dart';
import '../../domain/entities/plan_entity.dart';
import '../models/plan.dart';
import 'hero_art.dart';
import 'plan_artwork.dart';

/// Mantiene el aspecto original de las tarjetas.
///
/// - PlanCard: compatibilidad con otras pantallas todavía simuladas.
/// - PlanCard.fromEntity: datos reales provenientes de PlansBloc.
class PlanCard extends StatelessWidget {
  const PlanCard({super.key, required Plan plan, required this.onTap})
    : _legacyPlan = plan,
      _realPlan = null,
      activityName = null;

  const PlanCard.fromEntity({
    super.key,
    required PlanEntity plan,
    required this.onTap,
    this.activityName,
  }) : _realPlan = plan,
       _legacyPlan = null;

  final Plan? _legacyPlan;
  final PlanEntity? _realPlan;
  final String? activityName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final legacy = _legacyPlan;
    final real = _realPlan;
    final title = real?.title ?? legacy!.titulo;
    final place = real?.place ?? legacy!.lugar;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 164,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 108,
                child: real == null
                    ? HeroArt(plan: legacy!, showText: false)
                    : PlanArtwork(plan: real),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        place,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: RumboColors.musgo,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: real == null
                            ? [
                                Tag(legacy!.fecha.split(' · ').first),
                                Tag(
                                  legacy.dificultad,
                                  warn: legacy.dificultad == 'Exigente',
                                ),
                              ]
                            : [
                                if (real.startsAt != null)
                                  Tag(_shortDate(real.startsAt!)),
                                if (activityName != null) Tag(activityName!),
                                if (real.difficulty == PlanDifficulty.hard)
                                  const Tag('Exigente', warn: true),
                                if (real.status == PlanStatus.draft)
                                  const Tag('Borrador'),
                                if (real.status == PlanStatus.cancelled)
                                  const Tag('Cancelado'),
                                if (real.status == PlanStatus.finished)
                                  const Tag('Finalizado'),
                              ],
                      ),
                      const Spacer(),
                      if (real != null)
                        _RealPlanSummary(plan: real)
                      else
                        _LegacyPlanSummary(plan: legacy!),
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

class _RealPlanSummary extends StatelessWidget {
  const _RealPlanSummary({required this.plan});
  final PlanEntity plan;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.people_outline, size: 14, color: RumboColors.musgo),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            plan.maxParticipants == null
                ? 'Cupos por definir'
                : 'Máx. ${plan.maxParticipants}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: RumboColors.musgo, fontSize: 11.5),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            plan.budgetPerPerson == null
                ? 'Presupuesto pendiente'
                : plan.budgetPerPerson == 0
                ? 'Gratis'
                : '\$${_formatCop(plan.budgetPerPerson!)} COP',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _LegacyPlanSummary extends StatelessWidget {
  const _LegacyPlanSummary({required this.plan});
  final Plan plan;

  @override
  Widget build(BuildContext context) {
    return Row(
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
          style: const TextStyle(color: RumboColors.musgo, fontSize: 12),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            plan.precio == 'Gratis' ? 'Sin costo' : 'Desde ${plan.precio}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

String _shortDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day}/${local.month}';
}

String _formatCop(double value) {
  final integer = value.toStringAsFixed(0);
  return integer.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
}
