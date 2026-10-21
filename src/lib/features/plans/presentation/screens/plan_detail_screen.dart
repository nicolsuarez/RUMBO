import 'package:flutter/material.dart';

import '../../../../shared/components/avatar_stack.dart';
import '../../../../shared/components/kpi_card.dart';
import '../../../../shared/components/section_title.dart';
import '../../../../shared/components/tag.dart';
import '../../../../shared/painters/elevation_painter.dart';
import '../../../../shared/theme/rumbo_colors.dart';
import '../../../../shared/utils/name_utils.dart';

import '../components/hero_art.dart';
import '../models/plan.dart';

class PlanDetailScreen extends StatefulWidget {
  final Plan plan;
  final bool organizerOwnPlan;
  final bool joined;
  final bool Function() onJoinToggle;
  final VoidCallback onOpenChat;
  final VoidCallback? onStartRoute;

  const PlanDetailScreen({
    super.key,
    required this.plan,
    required this.organizerOwnPlan,
    required this.joined,
    required this.onJoinToggle,
    required this.onOpenChat,
    this.onStartRoute,
  });

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  late bool joined;

  @override
  void initState() {
    super.initState();
    joined = widget.joined;
  }

  @override
  void didUpdateWidget(covariant PlanDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.joined != widget.joined) {
      joined = widget.joined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.plan;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: HeroArt(plan: p, showText: false),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Etiquetas del plan.
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: p.tags
                        .map(
                          (tag) => Tag(
                            tag,
                            warn:
                                p.dificultad == 'Exigente' &&
                                tag == p.tags.first,
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 10),

                  // Título.
                  Text(
                    p.titulo,
                    style: const TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.7,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    p.lugar,
                    style: const TextStyle(color: RumboColors.musgo),
                  ),

                  const SizedBox(height: 16),

                  // Indicadores del recorrido.
                  Row(
                    children: [
                      Expanded(
                        child: KpiCard(value: p.distancia, label: 'distancia'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: KpiCard(value: p.desnivel, label: 'desnivel'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: KpiCard(
                          value: p.dificultad,
                          label: 'dificultad',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Información del organizador.
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: RumboColors.monte2,
                        child: Text(
                          initials(p.organizador),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        p.organizador,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(p.rolOrganizador),
                      trailing: const Tag('Organiza'),
                    ),
                  ),

                  // Descripción.
                  const SectionTitle('Cómo es la salida'),

                  Text(p.descripcion, style: const TextStyle(height: 1.62)),

                  // Perfil de elevación.
                  const SectionTitle('Perfil de la ruta'),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 85,
                            child: ElevationChart(
                              values: p.elevacion,
                              color: RumboColors.monte2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Punto más alto: ${p.desnivel} '
                            'de desnivel acumulado '
                            'en ${p.distancia}.',
                            style: const TextStyle(
                              color: RumboColors.musgo,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Elementos recomendados.
                  const SectionTitle('Qué llevar'),

                  ...p.llevar.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('•  '),
                          Expanded(child: Text(item)),
                        ],
                      ),
                    ),
                  ),

                  // Participantes del plan.
                  const SectionTitle('Quiénes van'),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const AvatarStack(),
                              Text(
                                '${p.van} de ${p.cupos} cupos',
                                style: const TextStyle(
                                  color: RumboColors.musgo,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          LinearProgressIndicator(
                            value: p.cupos > 0
                                ? (p.van / p.cupos).clamp(0.0, 1.0)
                                : 0.0,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(10),
                          ),

                          const SizedBox(height: 9),

                          const Text(
                            'El grupo se confirma cuando '
                            'haya mínimo 6 personas.',
                            style: TextStyle(
                              color: RumboColors.musgo,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // Barra inferior de inscripción.
      bottomSheet: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: const [BoxShadow(blurRadius: 16, color: Colors.black12)],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.precio == 'Gratis' ? 'Sin costo estimado' : p.precio,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      p.precio == 'Gratis'
                          ? 'sin presupuesto mínimo previsto'
                          : 'presupuesto mínimo estimado',
                      style: const TextStyle(
                        color: RumboColors.musgo,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              FilledButton(
                onPressed: () async {
                  // El organizador administra su propio plan.
                  if (widget.organizerOwnPlan) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vista de gestión del plan.'),
                      ),
                    );
                    return;
                  }

                  // Solicitar el cambio de inscripción.
                  final success = widget.onJoinToggle();

                  // Si el plan está lleno, no inscribirse.
                  if (!success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No hay cupos disponibles.'),
                      ),
                    );
                    return;
                  }

                  // Actualizar estado local.
                  setState(() {
                    joined = !joined;
                  });

                  // Mostrar confirmación si acaba de unirse.
                  if (joined) {
                    final openChat = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) {
                        return AlertDialog(
                          title: const Text('Te uniste al plan'),
                          content: Text(
                            'Ya eres parte del grupo de '
                            '${p.titulo}. Puedes abrir '
                            'el chat del grupo.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(dialogContext, false);
                              },
                              child: const Text('Cerrar'),
                            ),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(dialogContext, true);
                              },
                              child: const Text('Abrir chat'),
                            ),
                          ],
                        );
                      },
                    );

                    if (!mounted) return;

                    if (openChat == true) {
                      widget.onOpenChat();
                    }
                  }
                },

                child: Text(
                  widget.organizerOwnPlan
                      ? 'Gestionar inscritos'
                      : joined
                      ? 'Desunirme'
                      : p.van >= p.cupos
                      ? 'Sin cupos'
                      : 'Unirme al plan',
                ),
              ),
            ],
          ),
        ),
      ),

      // Iniciar recorrido, si está disponible.
      floatingActionButton: joined && widget.onStartRoute != null
          ? FloatingActionButton.extended(
              onPressed: widget.onStartRoute,
              icon: const Icon(Icons.navigation_outlined),
              label: const Text('Iniciar ruta'),
            )
          : null,
    );
  }
}
