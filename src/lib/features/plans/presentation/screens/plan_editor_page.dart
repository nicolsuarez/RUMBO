import 'package:flutter/material.dart';

import '../../domain/entities/plan_entity.dart';
import 'create_plan_screen.dart';

/// Adaptador para conservar la navegación actual de RumboShell y
/// PlansOrganizerPage sin duplicar formularios.
class PlanEditorPage extends StatelessWidget {
  const PlanEditorPage({super.key, this.initial, this.onSaved});

  final PlanEntity? initial;
  final VoidCallback? onSaved;

  @override
  Widget build(BuildContext context) =>
      CreatePlanScreen(initial: initial, onSaved: onSaved);
}
