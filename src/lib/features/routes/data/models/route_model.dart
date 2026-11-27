import '../../domain/entities/route_entity.dart';

class RouteModel {
  const RouteModel._();

  static RouteEntity fromJson(Map<String, dynamic> json) => RouteEntity(
    id: json['id_recorrido'] as String,
    enrollmentId: json['id_inscripcion'] as String,
    userId: json['id_usuario'] as String,
    planId: json['id_plan'] as String,
    startedAt: DateTime.parse(json['inicio'] as String),
    finishedAt: json['fin'] == null
        ? null
        : DateTime.parse(json['fin'] as String),
    status: switch (json['estado']) {
      'activo' => RouteStatus.active,
      'pausado' => RouteStatus.paused,
      'finalizado' => RouteStatus.finished,
      _ => throw FormatException(
        'Estado de recorrido desconocido: ${json['estado']}',
      ),
    },
    progress: (json['porcentaje_avance'] as num).toDouble(),
    distanceKm: (json['distancia_recorrida'] as num).toDouble(),
  );
}
