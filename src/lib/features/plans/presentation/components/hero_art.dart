import 'package:flutter/material.dart';

import '../models/plan.dart';

class HeroArt extends StatelessWidget {
  final Plan plan;
  final bool showText;

  const HeroArt({super.key, required this.plan, this.showText = true});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: plan.color1,
        image: DecorationImage(
          image: AssetImage(plan.imageAsset),
          fit: BoxFit.cover,
          onError: (_, _) {},
        ),
      ),
    );
  }
}
