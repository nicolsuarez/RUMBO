import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../shared/components/kpi_card.dart';
import '../../../../shared/components/tag.dart';
import '../../../../shared/painters/map_painter.dart';
import '../../../../shared/theme/rumbo_colors.dart';
import '../../../auth/presentation/bloc/auth/auth_bloc.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/entities/route_simulation_rate.dart';
import '../bloc/routes_bloc.dart';

enum _DeviationResult { safe, needHelp, timeout }

/// Contrato visual para Safety. El módulo receptor confirma y persiste la alerta.
enum RouteAlertKind { manual, deviation }

typedef RouteSafetyHandler = Future<void> Function(
  BuildContext context,
  String routeId,
  RouteAlertKind kind,
);

/// Un BLoC por pantalla, con identidad del plan real y sin GPS.
class RouteSimulationScreen extends StatelessWidget {
  const RouteSimulationScreen({
    super.key,
    required this.planId,
    required this.userId,
    required this.title,
    required this.place,
    required this.canStart,
    this.totalDistanceKm,
    this.onSafetyRequested,
  });

  final String planId;
  final String userId;
  final String title;
  final String place;
  final bool canStart;
  final double? totalDistanceKm;
  final RouteSafetyHandler? onSafetyRequested;

  @override
  Widget build(BuildContext context) => BlocBuilder<AuthBloc, AuthState>(
    builder: (context, session) {
      if (session is! AuthAuthenticated || session.user.id != userId) {
        return Scaffold(
          appBar: AppBar(title: const Text('Recorrido')),
          body: const Center(child: Text('Sesión no disponible. Vuelve a Mis planes.')),
        );
      }
      final allowed = canStart && RouteSimulationRate.hasDistance(totalDistanceKm);
      return BlocProvider<RoutesBloc>(
    key: ValueKey('$userId:$planId'),
    create: (_) => locator<RoutesBloc>()..add(RoutesLoadRequested(planId, allowAutomaticProgress: allowed, totalDistanceKm: totalDistanceKm)),
    child: _RouteSimulationView(
      planId: planId,
      title: title,
      place: place,
      canStart: allowed,
      totalDistanceKm: totalDistanceKm,
      onSafetyRequested: onSafetyRequested,
    ),
      );
    },
  );
}

class _RouteSimulationView extends StatefulWidget {
  const _RouteSimulationView({
    required this.planId,
    required this.title,
    required this.place,
    required this.canStart,
    required this.totalDistanceKm,
    required this.onSafetyRequested,
  });

  final String planId;
  final String title;
  final String place;
  final bool canStart;
  final double? totalDistanceKm;
  final RouteSafetyHandler? onSafetyRequested;

  @override
  State<_RouteSimulationView> createState() => _RouteSimulationViewState();
}

class _RouteSimulationViewState extends State<_RouteSimulationView> {
  bool _deviationAlert = true;
  bool _safetyBusy = false;

  @override
  Widget build(BuildContext context) => BlocBuilder<RoutesBloc, RoutesState>(
    builder: (context, state) {
      final route = state.route;
      final bloc = context.read<RoutesBloc>();
      final progress = route?.progress;
      final percent = progress == null ? '—' : '${progress.toStringAsFixed(2)}%';
      final label = switch (route?.status) {
        RouteStatus.active => 'Ruta en curso',
        RouteStatus.paused => 'Ruta pausada',
        RouteStatus.finished => 'Ruta finalizada',
        null => 'Sin iniciar',
      };
      // Estimación del tiempo de simulación, no de una caminata real.
      final remaining = progress == null || route!.status == RouteStatus.finished || !widget.canStart
          ? '—'
          : '${(((100 - progress) / bloc.effectiveProgressStep).ceil() * bloc.tickInterval.inSeconds / 60).ceil()} min';
      final canAlert = state.phase == RoutesPhase.ready &&
          (route?.isInProgress ?? false) && !_safetyBusy &&
          widget.onSafetyRequested != null;

      return Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              Text(widget.place, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, color: RumboColors.musgo)),
            ],
          ),
          actions: const [Padding(padding: EdgeInsets.only(right: 12),
            child: Tag('Simulación', warn: true))],
        ),
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (state.isBusy || state.phase == RoutesPhase.initial)
              const LinearProgressIndicator(),
            if (state.error != null) ...[
              Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No se pudo completar la operación.',
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  Text(state.error!),
                  TextButton.icon(
                    onPressed: () => bloc.add(RoutesLoadRequested(widget.planId, allowAutomaticProgress: widget.canStart, totalDistanceKm: widget.totalDistanceKm)),
                    icon: const Icon(Icons.refresh), label: const Text('Volver a consultar')),
                ],
              ))),
              const SizedBox(height: 8),
            ],
            Stack(children: [
              DemoMap(height: 500, progressPercent: state.route?.progress ?? 0),
              Positioned(top: 14, left: 14, child: _MapPill(text: label)),
              Positioned(top: 14, right: 14, child: _MapPill(text: percent)),
              Positioned(bottom: 16, left: 14, child: _MapPill(
                icon: Icons.timer_outlined, text: remaining == '—' ? 'Sin estimación' : '$remaining simulados')),
              Positioned(bottom: 16, right: 14, child: FloatingActionButton(
                heroTag: 'route_sos',
                backgroundColor: canAlert ? RumboColors.alerta : Colors.grey,
                foregroundColor: Colors.white,
                onPressed: canAlert ? () => _requestSafety(RouteAlertKind.manual) : null,
                tooltip: widget.onSafetyRequested == null ? 'Safety pendiente de integración' : 'SOS simulado',
                child: const Text('SOS', style: TextStyle(fontWeight: FontWeight.w900)),
              )),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: KpiCard(
                value: route == null ? '—' : '${route.distanceKm.toStringAsFixed(2)} km',
                label: 'distancia simulada registrada')),
              const SizedBox(width: 8),
              Expanded(child: KpiCard(value: remaining, label: 'tiempo simulado restante')),
            ]),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: progress == null ? 0.0 : progress / 100),
            const SizedBox(height: 10),
            if (state.canStart && widget.canStart)
              FilledButton.icon(
                onPressed: () => bloc.add(const RoutesStartRequested()),
                icon: const Icon(Icons.navigation_outlined),
                label: const Text('Iniciar recorrido simulado')),
            if (state.canStart && !widget.canStart)
              const Text('No hay recorrido disponible. Se requiere un plan publicado con distancia mayor a 0 y una inscripción confirmada.'),
            if (route != null && route.isInProgress) ...[
              if (!widget.canStart)
                const Text('El plan o la inscripción ya no permite continuar. Puedes finalizar el recorrido.'),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: !_safetyBusy && state.canPause
                      ? () => bloc.add(const RoutesPauseRequested())
                      : !_safetyBusy && state.canResume && widget.canStart
                          ? () => bloc.add(const RoutesResumeRequested()) : null,
                  icon: Icon(route.status == RouteStatus.paused ? Icons.play_arrow : Icons.pause),
                  label: Text(route.status == RouteStatus.paused ? 'Reanudar' : 'Pausar'),
                )),
                const SizedBox(width: 8),
                Expanded(child: FilledButton(
                  onPressed: state.canFinish && !_safetyBusy ? _confirmFinish : null,
                  child: const Text('Finalizar recorrido'),
                )),
              ]),
            ],
            if (route?.status == RouteStatus.finished)
              const Card(child: ListTile(leading: Icon(Icons.check_circle_outline),
                title: Text('Recorrido finalizado'),
                subtitle: Text('El avance final quedó guardado. No se puede reiniciar.'))),
            const SizedBox(height: 10),
            Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _deviationAlert,
                onChanged: canAlert ? (value) => setState(() => _deviationAlert = value) : null,
                title: const Text('Alerta automática por desvío', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(widget.onSafetyRequested == null
                    ? 'Pendiente de conexión con Safety.'
                    : 'Corredor ilustrativo; no utiliza GPS.'),
              ),
              OutlinedButton(
                onPressed: canAlert && _deviationAlert ? _showDeviation : null,
                child: const Text('Simular salida del corredor')),
              const Text('Las alertas de prueba no se envían a emergencias.',
                style: TextStyle(fontSize: 11.5, color: RumboColors.musgo)),
            ]))),
            const SizedBox(height: 8),
            const Text('Mapa ilustrativo y progreso simulado — no usan GPS real. '
                'Al salir se detiene el avance automático hasta reabrir el recorrido; '
                'el último progreso confirmado queda guardado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: RumboColors.musgo, fontSize: 11.5)),
          ],
        ),
      );
    },
  );

  Future<void> _confirmFinish() async {
    final yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Finalizar recorrido'),
      content: const Text('Se conservará el avance alcanzado. No podrás reanudarlo.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Volver')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Finalizar')),
      ],
    ));
    if (!mounted || yes != true) return;
    final bloc = context.read<RoutesBloc>();
    // Si un tick está escribiendo, el evento se procesa en su cola al terminar.
    bloc.add(const RoutesFinishRequested());
  }

  Future<void> _showDeviation() async {
    final result = await showDialog<_DeviationResult>(context: context,
      barrierDismissible: false, builder: (_) => const _DeviationCountdownDialog());
    if (!mounted) return;
    if (result == _DeviationResult.safe) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alerta cancelada.')));
    } else if (result == _DeviationResult.needHelp || result == _DeviationResult.timeout) {
      await _requestSafety(RouteAlertKind.deviation);
    }
  }

  Future<void> _requestSafety(RouteAlertKind kind) async {
    final handler = widget.onSafetyRequested;
    final route = context.read<RoutesBloc>().state.route;
    if (handler == null || route == null || !route.isInProgress || _safetyBusy) return;
    setState(() => _safetyBusy = true);
    try {
      // Safety es responsable de la confirmación y del resultado real de la RPC.
      await handler(context, route.id, kind);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible completar la solicitud de alerta.')));
    } finally {
      if (mounted) setState(() => _safetyBusy = false);
    }
  }
}

// Widget auxiliar privado de esta pantalla.
class _MapPill extends StatelessWidget {
  final IconData? icon;
  final String text;

  const _MapPill({this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black12)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: RumboColors.monte2),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: RumboColors.tinta,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviationCountdownDialog extends StatefulWidget {
  const _DeviationCountdownDialog();

  @override
  State<_DeviationCountdownDialog> createState() =>
      _DeviationCountdownDialogState();
}

class _DeviationCountdownDialogState extends State<_DeviationCountdownDialog> {
  static const int countdownSeconds = 10;

  int remainingSeconds = countdownSeconds;
  Timer? countdownTimer;

  @override
  void initState() {
    super.initState();

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!context.mounted) return;

      if (remainingSeconds <= 1) {
        timer.cancel();

        Navigator.of(context).pop(_DeviationResult.timeout);
        return;
      }

      setState(() {
        remainingSeconds--;
      });
    });
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: RumboColors.alerta,
          size: 48,
        ),

        title: const Text(
          '¡Te alejaste de la ruta!',
          textAlign: TextAlign.center,
        ),

        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Detectamos una desviación simulada. '
              '¿Te encuentras bien?',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            Text(
              '$remainingSeconds',
              style: const TextStyle(
                fontSize: 54,
                fontWeight: FontWeight.w900,
                color: RumboColors.alerta,
              ),
            ),

            const Text(
              'segundos restantes',
              style: TextStyle(color: RumboColors.musgo),
            ),

            const SizedBox(height: 14),

            LinearProgressIndicator(
              value: remainingSeconds / countdownSeconds,
              minHeight: 7,
              color: RumboColors.alerta,
            ),

            const SizedBox(height: 16),

            const Text(
              'Si no respondes, se simulará una solicitud de '
              'alerta por desvío. Safety pedirá confirmación antes de registrarla.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(_DeviationResult.needHelp);
            },
            child: const Text('Necesito ayuda'),
          ),

          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(_DeviationResult.safe);
            },
            child: const Text('Estoy bien'),
          ),
        ],
      ),
    );
  }
}
