import 'package:flutter/material.dart';

import '../../../../shared/theme/rumbo_colors.dart';

class ApprovalCard extends StatefulWidget {
  final String name;
  final String plan;
  final String note;
  final String initials;

  const ApprovalCard({
    super.key,
    required this.name,
    required this.plan,
    required this.note,
    required this.initials,
  });

  @override
  State<ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends State<ApprovalCard> {
  bool resolved = false;

  @override
  Widget build(BuildContext context) {
    if (resolved) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: RumboColors.rosado,
                  radius: 20,
                  child: Text(
                    widget.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'pide cupo en ${widget.plan}',
                        style: const TextStyle(
                          color: RumboColors.musgo,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        widget.note,
                        style: const TextStyle(
                          color: RumboColors.musgo,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      setState(() => resolved = true);
                    },
                    child: const Text('Aceptar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => resolved = true);
                    },
                    child: const Text('Rechazar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
