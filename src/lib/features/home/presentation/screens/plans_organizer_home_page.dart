import 'package:flutter/material.dart';

import 'organizer_panel.dart';

/// Mantiene la navegación existente en RumboShell sin duplicar el panel.
class PlansOrganizerHomePage extends StatelessWidget {
  const PlansOrganizerHomePage({
    super.key,
    required this.onCreate,
    required this.onMyPlans,
  });

  final VoidCallback onCreate;
  final VoidCallback onMyPlans;

  @override
  Widget build(BuildContext context) {
    return OrganizerPanel(onCreate: onCreate, onMyPlans: onMyPlans);
  }
}
