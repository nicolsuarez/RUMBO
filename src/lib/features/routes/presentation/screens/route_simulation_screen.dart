import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/components/kpi_card.dart';
import '../../../../shared/components/tag.dart';
import '../../../../shared/painters/map_painter.dart';
import '../../../../shared/theme/rumbo_colors.dart';

import '../../../plans/presentation/models/plan.dart';

enum _DeviationResult { safe, needHelp, timeout }

class RouteSimulationScreen extends StatefulWidget {
  final Plan plan;
  final VoidCallback onFinish;

  const RouteSimulationScreen({
    super.key,
    required this.plan,
    required this.onFinish,
  });

  @override
  State<RouteSimulationScreen> createState() => _RouteSimulationScreenState();
}

class _RouteSimulationScreenState extends State<RouteSimulationScreen> {
  double progress = 0.18;
  bool deviationAlert = true;
  Timer? timer;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        progress = math.min(1.0, progress + 0.004);
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalKm =
        double.tryParse(widget.plan.distancia.split(' ').first) ?? 5.0;

    final done = totalKm * progress;

    final remainingMin = ((1 - progress) * totalKm * 11).round();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.plan.titulo,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text(
              widget.plan.lugar,
              style: const TextStyle(fontSize: 11.5, color: RumboColors.musgo),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Tag('Simulación', warn: true),
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Mapa y controles superpuestos.
          Stack(
            children: [
              const DemoMap(height: 500),

              const Positioned(
                top: 14,
                left: 14,
                child: _MapPill(icon: Icons.circle, text: 'Ruta en curso'),
              ),

              Positioned(
                top: 14,
                right: 14,
                child: _MapPill(text: '${(progress * 100).round()}%'),
              ),

              Positioned(
                bottom: 16,
                left: 14,
                child: _MapPill(
                  icon: Icons.timer_outlined,
                  text: '$remainingMin min restantes',
                ),
              ),

              Positioned(
                bottom: 16,
                right: 14,
                child: FloatingActionButton(
                  heroTag: 'route_sos',
                  backgroundColor: RumboColors.alerta,
                  foregroundColor: Colors.white,
                  onPressed: () => _showSOS(context),
                  child: const Text(
                    'SOS',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Indicadores del recorrido.
          Row(
            children: [
              Expanded(
                child: KpiCard(
                  value: '${done.toStringAsFixed(1)} km',
                  label: '${(progress * 100).round()}% del recorrido',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: KpiCard(
                  value: '$remainingMin min',
                  label: 'tiempo restante',
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Simulación de desvío de ruta.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: deviationAlert,
                    onChanged: (value) {
                      setState(() {
                        deviationAlert = value;
                      });
                    },
                    title: const Text(
                      'Alerta automática por desvío',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      deviationAlert
                          ? 'Activa: usa un corredor de '
                                'referencia alrededor de la ruta.'
                          : 'Desactivada: no se generarán '
                                'alertas automáticas.',
                    ),
                  ),

                  OutlinedButton(
                    onPressed: deviationAlert
                        ? () => _showDeviation(context)
                        : null,
                    child: const Text('Simular salida del corredor'),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Referencia del prototipo: corredor '
                    'aproximado de 30 m, ajustable según '
                    'terreno y precisión GPS.',
                    style: TextStyle(fontSize: 11.5, color: RumboColors.musgo),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          OutlinedButton(
            onPressed: () {
              widget.onFinish();
              Navigator.pop(context);
            },
            child: const Text('Finalizar recorrido'),
          ),

          const SizedBox(height: 8),

          const Text(
            'Mapa y tiempo simulados — no usan GPS real.',
            textAlign: TextAlign.center,
            style: TextStyle(color: RumboColors.musgo, fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  Future<void> _showSOS(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Activar SOS'),
        content: const Text(
          'Se generará un reporte de emergencia '
          'simulado. No se enviará ninguna '
          'notificación real.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Generar reporte'),
          ),
        ],
      ),
    );

    if (!context.mounted || confirmed != true) return;

    await _showAlertReport(context, reason: 'SOS activado manualmente');
  }

  Future<void> _showDeviation(BuildContext context) async {
    final result = await showDialog<_DeviationResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DeviationCountdownDialog(),
    );

    if (!mounted) return;

    switch (result) {
      case _DeviationResult.safe:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Confirmación recibida. Alerta cancelada.'),
          ),
        );

      case _DeviationResult.needHelp:
        await _showAlertReport(context, reason: 'Solicitud manual de ayuda');

      case _DeviationResult.timeout:
        await _showAlertReport(
          context,
          reason: 'Desviación sin respuesta durante 10 segundos',
        );

      case null:
        // El diálogo se cerró sin confirmar un resultado.
        break;
    }
  }

  Future<void> _showAlertReport(
    BuildContext context, {
    required String reason,
  }) async {
    final now = DateTime.now();

    final formattedDate =
        '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';

    final formattedTime = TimeOfDay.fromDateTime(now).format(context);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.shield_outlined,
          color: RumboColors.alerta,
          size: 48,
        ),

        title: const Text('Reporte SOS generado'),

        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Tag('SIMULACIÓN — NO ENVIADO', warn: true),

            const SizedBox(height: 16),

            Text('Motivo: $reason'),

            const SizedBox(height: 12),

            Text('Fecha: $formattedDate'),

            Text('Hora: $formattedTime'),

            const SizedBox(height: 12),

            Text('Actividad: ${widget.plan.titulo}'),

            Text('Zona del recorrido: ${widget.plan.lugar}'),

            const SizedBox(height: 12),

            const Text(
              'Ubicación actual: No disponible '
              '(GPS no conectado)',
            ),

            const SizedBox(height: 12),

            const Text(
              'Destinatarios previstos:\n'
              '• Organizador del plan\n'
              '• Contactos de emergencia',
            ),

            const SizedBox(height: 12),

            const Text(
              'Estado de entrega: No enviado. '
              'No hay un servicio de emergencias '
              'configurado.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: RumboColors.alerta,
              ),
            ),
          ],
        ),

        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
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
            Icon(icon, size: 13, color: Colors.green),
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
              'Si no respondes, RUMBO generará '
              'automáticamente un reporte SOS '
              'de demostración.',
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
