import 'package:flutter/material.dart';

import '../../../../shared/theme/rumbo_colors.dart';
import '../../domain/entities/plan_entity.dart';

/// Fondo visual para planes reales. El repositorio transforma el path
/// interno del bucket en URL pública; este widget nunca consulta Supabase.
class PlanArtwork extends StatelessWidget {
  const PlanArtwork({super.key, required this.plan});

  final PlanEntity plan;

  @override
  Widget build(BuildContext context) {
    final imageUrl = plan.imageUrl?.trim();
    final uri = imageUrl == null ? null : Uri.tryParse(imageUrl);
    final isRemoteImage =
        uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;

    if (isRemoteImage) {
      return Image.network(
        imageUrl!,
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
