import 'package:flutter/material.dart';

import '../../../../shared/theme/rumbo_colors.dart';
import '../../domain/entities/plan_entity.dart';

/// Fondo visual para planes reales. Hasta integrar Supabase Storage,
/// las rutas internas del bucket muestran el arte de reserva de RUMBO.
class PlanArtwork extends StatelessWidget {
  const PlanArtwork({super.key, required this.plan});

  final PlanEntity plan;

  @override
  Widget build(BuildContext context) {
    final imagePath = plan.imagePath?.trim();
    final uri = imagePath == null ? null : Uri.tryParse(imagePath);
    final isRemoteImage =
        uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;

    if (isRemoteImage) {
      return Image.network(
        imagePath!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const _FallbackArtwork(),
      );
    }

    return const _FallbackArtwork();
  }
}

class _FallbackArtwork extends StatelessWidget {
  const _FallbackArtwork();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [RumboColors.monte2, RumboColors.monte],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.landscape_outlined,
          color: RumboColors.guayacan,
          size: 46,
        ),
      ),
    );
  }
}
