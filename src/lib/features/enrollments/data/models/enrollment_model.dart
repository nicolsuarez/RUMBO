import '../../domain/entities/enrollment_entity.dart';
import '../../../plans/domain/entities/plan_entity.dart';

class EnrollmentModel {
  const EnrollmentModel._();

  static EnrollmentEntity fromJson(Map<String, dynamic> json) {
    final relatedPlan = json['plan'];
    final plan = relatedPlan is Map<String, dynamic> ? relatedPlan : null;
    final relatedRoute = json['recorrido'];
    final route = relatedRoute is List && relatedRoute.isNotEmpty
        ? relatedRoute.first
        : relatedRoute;
    return EnrollmentEntity(
      id: json['id_inscripcion'] as String,
      userId: json['id_usuario'] as String,
      planId: json['id_plan'] as String,
      status: enrollmentStatusFromDb(json['estado'] as String),
      enrolledAt: DateTime.parse(json['fecha_inscripcion'] as String),
      planTitle: plan?['titulo'] as String?,
      planPlace: plan?['lugar'] as String?,
      planStatus: plan?['estado'] == null
          ? null
          : planStatusFromDb(plan!['estado'] as String),
      planDistanceKm: (plan?['distancia_km'] as num?)?.toDouble(),
      existingRouteId: route is Map ? route['id_recorrido'] as String? : null,
      planStartsAt: plan?['fecha_inicio'] == null
          ? null
          : DateTime.parse(plan!['fecha_inicio'] as String),
    );
  }

  static PlanAvailability availabilityFromJson(Map<String, dynamic> json) =>
      PlanAvailability(
        occupied: (json['cupos_ocupados'] as num).toInt(),
        capacity: (json['cupos_maximos'] as num?)?.toInt() ?? 0,
        pendingRequests: (json['solicitudes_pendientes'] as num).toInt(),
      );
}
