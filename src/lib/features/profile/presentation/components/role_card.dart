import 'package:flutter/material.dart';

import '../../../../shared/components/tag.dart';
import '../../../../shared/theme/rumbo_colors.dart';

// solo dibuja la card para diferenciar las opciones de rol
class RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String title;
  final String text;
  final bool highlighted;
  final VoidCallback onTap;

  const RoleCard({
    super.key,
    required this.icon,
    required this.label,
    required this.title,
    required this.text,
    this.highlighted = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 105,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: highlighted
                      ? [RumboColors.monte, const Color(0xFF8FA06B)]
                      : [RumboColors.teal, RumboColors.monte2],
                ),
              ),
              child: Center(
                child: Icon(icon, color: RumboColors.guayacan, size: 48),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Tag(label, sun: highlighted),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    text,
                    style: const TextStyle(
                      color: RumboColors.musgo,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
