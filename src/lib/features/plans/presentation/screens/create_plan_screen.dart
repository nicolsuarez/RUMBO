import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/components/app_field.dart';
import '../../../../shared/theme/rumbo_colors.dart';

import '../components/hero_plan_card.dart';
import '../models/plan.dart';

class CreatePlanScreen extends StatefulWidget {
  final ValueChanged<Plan> onCreate;

  const CreatePlanScreen({super.key, required this.onCreate});

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  // Paso actual del formulario: 0, 1 o 2.
  int step = 0;

  // Opciones del plan.
  int cupos = 10;
  String dif = 'Media';

  // Controladores de los campos de texto.
  final title = TextEditingController();
  final place = TextEditingController();
  final date = TextEditingController();
  final time = TextEditingController();
  final desc = TextEditingController();

  @override
  void dispose() {
    title.dispose();
    place.dispose();
    date.dispose();
    time.dispose();
    desc.dispose();

    super.dispose();
  }

  void publishPlan() {
    final plan = _preview();

    // Entregar el nuevo plan al widget padre.
    widget.onCreate(plan);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Plan publicado')));

    // Reiniciar el formulario.
    title.clear();
    place.clear();
    date.clear();
    time.clear();
    desc.clear();

    setState(() {
      step = 0;
      cupos = 10;
      dif = 'Media';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
      children: [
        const Text(
          'Crear un plan',
          style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
        ),

        const SizedBox(height: 12),

        LinearProgressIndicator(
          value: (step + 1) / 3,
          minHeight: 5,
          borderRadius: BorderRadius.circular(10),
          color: RumboColors.guayacan,
        ),

        const SizedBox(height: 20),

        // PASO 1: Información básica.
        if (step == 0) ...[
          const Text(
            'Lo esencial',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 14),

          AppField(
            controller: title,
            label: 'Nombre del plan',
            hint: 'Caminata al Cerro de la Bandera',
          ),

          AppField(controller: place, label: 'Lugar', hint: 'Pance, Cali'),

          AppField(controller: date, label: 'Fecha', hint: 'sáb 26 sep'),

          AppField(controller: time, label: 'Hora', hint: '5:00 a.m.'),

          FilledButton(
            onPressed: () {
              setState(() => step = 1);
            },
            child: const Text('Continuar'),
          ),
        ],

        // PASO 2: Dificultad, cupos y descripción.
        if (step == 1) ...[
          const Text(
            'Dificultad y cupos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 14),

          Wrap(
            spacing: 8,
            children: ['Suave', 'Media', 'Exigente'].map((value) {
              return ChoiceChip(
                label: Text(value),
                selected: dif == value,
                onSelected: (_) {
                  setState(() => dif = value);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 18),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Número de cupos',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      setState(() {
                        cupos = math.max(2, cupos - 1);
                      });
                    },
                    icon: const Icon(Icons.remove),
                  ),

                  Text(
                    '$cupos',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      setState(() {
                        cupos = math.min(30, cupos + 1);
                      });
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          ),

          AppField(
            controller: desc,
            label: 'Descripción',
            hint: 'Cuenta cómo será la salida…',
            maxLines: 4,
          ),

          FilledButton(
            onPressed: () {
              setState(() => step = 2);
            },
            child: const Text('Continuar'),
          ),

          const SizedBox(height: 8),

          OutlinedButton(
            onPressed: () {
              setState(() => step = 0);
            },
            child: const Text('Atrás'),
          ),
        ],

        // PASO 3: Vista previa y publicación.
        if (step == 2) ...[
          const Text(
            'Revisar y publicar',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 14),

          HeroPlanCard(plan: _preview(), onTap: () {}),

          const SizedBox(height: 18),

          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: RumboColors.guayacan,
              foregroundColor: RumboColors.tinta,
            ),
            onPressed: publishPlan,
            child: const Text('Publicar plan'),
          ),

          const SizedBox(height: 8),

          OutlinedButton(
            onPressed: () {
              setState(() => step = 1);
            },
            child: const Text('Atrás'),
          ),
        ],
      ],
    );
  }

  // Construye el plan a partir de los datos del formulario.
  Plan _preview() {
    return Plan(
      id: 'nuevo_${DateTime.now().millisecondsSinceEpoch}',

      titulo: title.text.trim().isEmpty
          ? 'Caminata al Cerro de la Bandera'
          : title.text.trim(),

      lugar: place.text.trim().isEmpty ? 'Pance, Cali' : place.text.trim(),

      fecha:
          '${date.text.trim().isEmpty ? 'sáb 26 sep' : date.text.trim()}'
          ' · '
          '${time.text.trim().isEmpty ? '5:00 a.m.' : time.text.trim()}',

      dificultad: dif,
      distancia: '7 km',
      desnivel: '340 m',
      cupos: cupos,
      van: 1,
      precio: 'Gratis',
      organizador: 'Ines Martínez',
      rolOrganizador: 'Tu primer plan',
      tags: const ['Senderismo', 'Nuevo'],
      color1: RumboColors.monte,
      color2: const Color(0xFFA9B27A),
      elevacion: const [14, 26, 38, 52, 66, 78, 88, 92, 80, 64, 48, 32, 20, 12],
      descripcion: desc.text.trim().isEmpty
          ? 'Subida constante por camino de herradura, '
                'con sombra casi todo el recorrido y un charco '
                'al final para refrescarse.'
          : desc.text.trim(),
      llevar: const [
        'Agua suficiente',
        'Calzado con agarre',
        'Snack para el camino',
      ],
      imageAsset: 'assets/images/pico_de_loro.png',
    );
  }
}
