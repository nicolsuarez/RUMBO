import '../../domain/entities/enrollment_entity.dart';

class EnrollmentModel {
  const EnrollmentModel._();

  static EnrollmentEntity fromJson(Map<String, dynamic> json) {
    final relatedPlan = json['plan'];
    final plan = relatedPlan is Map<String, dynamic> ? relatedPlan : null;
    return EnrollmentEntity(
      id: json['id_inscripcion'] as String,
      userId: json['id_usuario'] as String,
      planId: json['id_plan'] as String,
      status: enrollmentStatusFromDb(json['estado'] as String),
      enrolledAt: DateTime.parse(json['fecha_inscripcion'] as String),
      planTitle: plan?['titulo'] as String?,
      planPlace: plan?['lugar'] as String?,
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
