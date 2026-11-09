import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/components/avatar_stack.dart';
import '../../../../shared/components/kpi_card.dart';
import '../../../../shared/components/section_title.dart';
import '../../../../shared/components/tag.dart';
import '../../../../shared/theme/rumbo_colors.dart';
import '../../../../shared/utils/name_utils.dart';
import '../../domain/entities/plan_entity.dart';
import '../bloc/plans_bloc.dart';
import '../components/hero_art.dart';
import '../components/plan_artwork.dart';
import '../models/plan.dart';
import 'plan_editor_page.dart';

/// Detalle visual único de RUMBO.
///
/// [PlanDetailScreen.fromEntity] es la entrada definitiva para planes reales.
/// El constructor original sigue disponible temporalmente porque RumboShell,
/// Chat y Routes aún usan Plan/inscripciones simuladas. Se retirará al integrar
/// Enrollments y migrar el flujo de participantes de Mis planes.
class PlanDetailScreen extends StatefulWidget {
  const PlanDetailScreen({
    super.key,
    required Plan plan,
    required this.organizerOwnPlan,
    required this.joined,
    required bool Function() onJoinToggle,
    required VoidCallback onOpenChat,
    this.onStartRoute,
  })  : _legacyPlan = plan,
        _realPlan = null,
        _onJoinToggle = onJoinToggle,
        _onOpenChat = onOpenChat;

  const PlanDetailScreen.fromEntity({
    super.key,
    required PlanEntity plan,
    this.organizerOwnPlan = false,
  })  : _realPlan = plan,
        _legacyPlan = null,
        joined = false,
        _onJoinToggle = null,
        _onOpenChat = null,
        onStartRoute = null;

  final Plan? _legacyPlan;
  final PlanEntity? _realPlan;
  final bool organizerOwnPlan;
  final bool joined;
  final bool Function()? _onJoinToggle;
  final VoidCallback? _onOpenChat;
  final VoidCallback? onStartRoute;

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  late bool _joined;

  @override
  void initState() {
    super.initState();
    _joined = widget.joined;
  }

  @override
  void didUpdateWidget(covariant PlanDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.joined != widget.joined) {
      _joined = widget.joined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final original = widget._realPlan;
    if (original == null) {
      // El flujo temporal de Mis planes no necesita PlansBloc.
      return _detail(context, real: null, legacy: widget._legacyPlan!);
    }

    // Si se editó o canceló un plan propio, reflejar el dato actualizado.
    return BlocBuilder<PlansBloc, PlansState>(
      builder: (context, state) {
        final candidates = [...state.mine, ...state.published];
        var current = original;
        for (final candidate in candidates) {
          if (candidate.id == original.id) {
            current = candidate;
            break;
          }
        }
        String? activityName;
        for (final activity in state.activities) {
          if (activity.id == current.activityTypeId) {
            activityName = activity.name;
            break;
          }
        }
        return _detail(
          context,
          real: current,
          legacy: null,
          activityName: activityName,
        );
      },
    );
  }

  Widget _detail(
    BuildContext context, {
    required PlanEntity? real,
    required Plan? legacy,
    String? activityName,
  }) {
    final title = real?.title ?? legacy!.titulo;
    final place = real?.place ?? legacy!.lugar;
    final description = real?.description ?? legacy!.descripcion;
    final difficulty = real == null
        ? legacy!.dificultad
        : switch (real.difficulty) {
            PlanDifficulty.easy => 'Suave',
            PlanDifficulty.medium => 'Media',
            PlanDifficulty.hard => 'Exigente',
            null => null,
          };
    final distance = real == null
        ? legacy!.distancia
        : real.distanceKm == null
            ? null
            : '${_formatDistance(real.distanceKm!)} km';
    final date = real == null ? legacy!.fecha : _formatDate(real.startsAt);
    final price = real == null
        ? legacy!.precio == 'Gratis'
            ? 'Gratis'
            : legacy!.precio
        : _formatBudget(real.budgetPerPerson);
    final tags = real == null
        ? legacy!.tags
        : <String>[
            if (activityName != null) activityName,
            if (difficulty != null) difficulty,
            if (real.mode != null)
              real.mode == PlanMode.private ? 'Privado' : 'Público',
            if (real.status != PlanStatus.published)
              _statusLabel(real.status),
          ];

    final metrics = <({String value, String label})>[
      if (distance != null) (value: distance, label: 'distancia'),
      if (difficulty != null) (value: difficulty, label: 'dificultad'),
      if (real != null && real.maxParticipants != null)
        (value: '${real.maxParticipants}', label: 'cupos máx.'),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: real == null
                  ? HeroArt(plan: legacy!, showText: false)
                  : PlanArtwork(plan: real),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 145),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tags.isNotEmpty)
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: tags
                          .map((value) => Tag(
                                value,
                                warn: value == 'Exigente' ||
                                    value == 'Cancelado',
                              ))
                          .toList(),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place,
                    style: const TextStyle(color: RumboColors.musgo),
                  ),
                  if (metrics.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        for (var i = 0; i < metrics.length; i++) ...[
                          if (i != 0) const SizedBox(width: 8),
                          Expanded(
                            child: KpiCard(
                              value: metrics[i].value,
                              label: metrics[i].label,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (real != null)
                    const Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: RumboColors.monte2,
                          child: Icon(Icons.person_outline,
                              color: Colors.white),
                        ),
                        title: Text('Organizador del plan'),
                        subtitle: Text(
                          'El perfil público estará disponible al integrar Profile.',
                        ),
                        trailing: Tag('Organiza'),
                      ),
                    )
                  else
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: RumboColors.monte2,
                          child: Text(
                            initials(legacy!.organizador),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          legacy!.organizador,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(legacy!.rolOrganizador),
                        trailing: const Tag('Organiza'),
                      ),
                    ),
                  const SectionTitle('Cómo es la salida'),
                  Text(description, style: const TextStyle(height: 1.62)),
                  const SectionTitle('Información de la actividad'),
                  Card(
                    child: Column(
                      children: [
                        _infoRow(Icons.event_outlined, 'Fecha y hora', date),
                        if (real != null && real.mode != null)
                          _infoRow(
                            Icons.lock_outline,
                            'Modalidad',
                            real.mode == PlanMode.private
                                ? 'Privado · requiere aprobación'
                                : 'Público · inscripción directa',
                          ),
                        if (real != null)
                          _infoRow(
                            Icons.people_outline,
                            'Participantes',
                            'Mín. ${real.minParticipants ?? 'Por definir'} · '
                                'máx. ${real.maxParticipants ?? 'Por definir'}',
                          ),
                        _infoRow(
                          Icons.payments_outlined,
                          'Presupuesto estimado por persona',
                          price,
                        ),
                      ],
                    ),
                  ),
                  if (legacy != null && legacy.llevar.isNotEmpty) ...[
                    const SectionTitle('Qué llevar'),
                    for (final item in legacy.llevar)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('•  '),
                            Expanded(child: Text(item)),
                          ],
                        ),
                      ),
                  ],
                  const SectionTitle('Quiénes van'),
                  real == null
                      ? _legacyParticipants(legacy!)
                      : Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cupo máximo: '
                                  '${real.maxParticipants?.toString() ?? 'Por definir'}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'La lista de participantes y los cupos ocupados '
                                  'se mostrarán cuando se integre Enrollments.',
                                  style: TextStyle(color: RumboColors.musgo),
                                ),
                                if (real.minParticipants != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Mínimo para realizar la actividad: '
                                    '${real.minParticipants} personas.',
                                  ),
                                ],
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
      bottomSheet: _bottomBar(context, real: real, legacy: legacy, price: price),
      floatingActionButton: legacy != null &&
              _joined &&
              widget.onStartRoute != null
          ? FloatingActionButton.extended(
              onPressed: widget.onStartRoute,
              icon: const Icon(Icons.navigation_outlined),
              label: const Text('Iniciar ruta'),
            )
          : null,
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => ListTile(
        leading: Icon(icon, color: RumboColors.monte2),
        title: Text(label, style: const TextStyle(fontSize: 12)),
        subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      );

  Widget _legacyParticipants(Plan plan) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AvatarStack(),
                  Text(
                    '${plan.van} de ${plan.cupos} cupos',
                    style: const TextStyle(
                      color: RumboColors.musgo,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: plan.cupos > 0
                    ? (plan.van / plan.cupos).clamp(0.0, 1.0)
                    : 0.0,
                minHeight: 6,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 9),
              const Text(
                'Inscripciones temporales de la maqueta. '
                'Se reemplazarán por Enrollments.',
                style: TextStyle(color: RumboColors.musgo, fontSize: 12.5),
              ),
            ],
          ),
        ),
      );

  Widget _bottomBar(
    BuildContext context, {
    required PlanEntity? real,
    required Plan? legacy,
    required String price,
  }) {
    final canEditReal = real != null &&
        widget.organizerOwnPlan &&
        (real.status == PlanStatus.draft ||
            real.status == PlanStatus.published);
    final isLegacy = legacy != null;
    return SafeArea(
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
                    price,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    real != null
                        ? 'por persona · estimado'
                        : 'presupuesto estimado',
                    style: const TextStyle(
                      color: RumboColors.musgo,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              flex: 2,
              child: FilledButton(
              onPressed: isLegacy
                  ? _legacyJoinAction
                  : canEditReal
                      ? () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => Scaffold(
                                appBar: AppBar(title: const Text('Editar plan')),
                                body: PlanEditorPage(initial: real),
                              ),
                            ),
                          )
                      : null,
              child: Text(
                isLegacy
                    ? widget.organizerOwnPlan
                        ? 'Gestionar inscritos'
                        : _joined
                            ? 'Desunirme'
                            : legacy!.van >= legacy!.cupos
                                ? 'Sin cupos'
                                : 'Unirme al plan'
                    : canEditReal
                        ? 'Editar plan'
                        : real!.status == PlanStatus.published
                            ? 'Inscripciones pronto'
                            : _statusLabel(real.status),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _legacyJoinAction() async {
    final plan = widget._legacyPlan!;
    if (widget.organizerOwnPlan) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vista de gestión del plan.')),
      );
      return;
    }
    final success = widget._onJoinToggle?.call() ?? false;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cupos disponibles.')),
      );
      return;
    }
    setState(() => _joined = !_joined);
    if (!_joined) return;
    final openChat = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Te uniste al plan'),
        content: Text(
          'Ya eres parte del grupo de ${plan.titulo}. '
          'Puedes abrir el chat del grupo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cerrar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Abrir chat'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (openChat == true) widget._onOpenChat?.call();
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return 'Por definir';
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} · $hour:$minute';
}

String _formatDistance(double km) {
  if (km == km.roundToDouble()) return km.toStringAsFixed(0);
  return km.toStringAsFixed(1);
}

String _formatBudget(double? amount) {
  if (amount == null) return 'Por definir';
  if (amount == 0) return 'Gratis';
  final digits = amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => '.',
      );
  return '\$$digits COP';
}

String _statusLabel(PlanStatus status) => switch (status) {
      PlanStatus.draft => 'Borrador',
      PlanStatus.published => 'Publicado',
      PlanStatus.cancelled => 'Cancelado',
      PlanStatus.finished => 'Finalizado',
    };
