import 'package:flutter/material.dart';

import '../theme/rumbo_colors.dart';

// muestra un stack de varias personas (o avatares)
// para representar a los participantes de un plan
class AvatarStack extends StatelessWidget {
  const AvatarStack({super.key});

  @override
  Widget build(BuildContext context) {
    final data = [
      ('MJ', RumboColors.teal),
      ('LS', RumboColors.rosado),
      ('DC', RumboColors.monte2),
      ('+6', RumboColors.guayacan),
    ];

    return SizedBox(
      width: 92,
      height: 30,
      child: Stack(
        children: [
          for (int i = 0; i < data.length; i++)
            Positioned(
              left: i * 20.0,
              child: CircleAvatar(
                radius: 15,
                backgroundColor: data[i].$2,
                child: Text(
                  data[i].$1,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: i == 3 ? RumboColors.tinta : Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
