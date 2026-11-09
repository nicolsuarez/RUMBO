import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/theme/rumbo_colors.dart';
import '../../domain/entities/plan_entity.dart';
import '../models/plan.dart';
import 'hero_art.dart';
import 'plan_artwork.dart';

/// Conserva el diseño original. En modo real no inventa cupos ocupados.
class HeroPlanCard extends StatelessWidget {
  const HeroPlanCard({super.key, required Plan plan, required this.onTap})
    : _legacyPlan = plan,
      _realPlan = null;

  const HeroPlanCard.fromEntity({
    super.key,
    required PlanEntity plan,
    required this.onTap,
  }) : _realPlan = plan,
       _legacyPlan = null;

  final Plan? _legacyPlan;
  final PlanEntity? _realPlan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final legacy = _legacyPlan;
    final real = _realPlan;

    final badge = real != null
        ? real.mode == PlanMode.private
              ? 'Requiere aprobación'
              : 'Inscripción abierta'
        : 'Quedan ${math.max(0, legacy!.cupos - legacy!.van)} cupos';

    final title = real?.title ?? legacy!.titulo;
    final subtitle = real == null
        ? '${legacy!.lugar} · ${legacy!.fecha}'
        : '${real.place}${real.startsAt == null ? '' : ' · ${_date(real.startsAt!)}'}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 205,
          child: Stack(
            fit: StackFit.expand,
            children: [
              real == null
                  ? HeroArt(plan: legacy!, showText: false)
                  : PlanArtwork(plan: real),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xDD1A2013)],
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: RumboColors.guayacan,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: RumboColors.tinta,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE9E4D0),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _date(DateTime value) {
  final date = value.toLocal();
  return '${date.day}/${date.month}/${date.year}';
}
