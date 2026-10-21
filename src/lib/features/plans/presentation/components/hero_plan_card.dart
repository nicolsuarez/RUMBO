import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/theme/rumbo_colors.dart';
import '../models/plan.dart';
import 'hero_art.dart';

class HeroPlanCard extends StatelessWidget {
  final Plan plan;
  final VoidCallback onTap;

  const HeroPlanCard({super.key, required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 205,
          child: Stack(
            fit: StackFit.expand,
            children: [
              HeroArt(plan: plan, showText: false),

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
                        'Quedan ${math.max(0, plan.cupos - plan.van)} cupos',
                        style: const TextStyle(
                          color: RumboColors.tinta,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      plan.titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${plan.lugar} · ${plan.fecha}',
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
