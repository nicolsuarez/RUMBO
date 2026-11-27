/// Estados de un recorrido simulado, independientes de Supabase.
enum RouteStatus { active, paused, finished }

class RouteEntity {
  const RouteEntity({
    required this.id,
    required this.enrollmentId,
    required this.userId,
    required this.planId,
    required this.startedAt,
    required this.status,
    required this.progress,
    required this.distanceKm,
    this.finishedAt,
  });

  final String id;
  final String enrollmentId;
  final String userId;
  final String planId;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final RouteStatus status;

  /// Porcentaje absoluto confirmado por el servidor (0–100).
  final double progress;

  /// Distancia simulada en kilómetros, nunca una medición GPS.
  final double distanceKm;

  bool get isInProgress =>
      status == RouteStatus.active || status == RouteStatus.paused;
}
