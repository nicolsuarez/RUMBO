import '../../domain/entities/plan_entity.dart';
import '../../domain/entities/plan_input.dart';

/// Adaptador PostgreSQL <-> dominio; aquí sí se conocen los nombres SQL.
class PlanModel {
  const PlanModel._();

  static PlanEntity fromJson(Map<String, dynamic> json, {String? imageUrl}) =>
      PlanEntity(
        id: json['id_plan'] as String,
        organizerId: json['id_organizador'] as String,
        title: json['titulo'] as String,
        description: json['descripcion'] as String,
        place: json['lugar'] as String,
        startsAt: _date(json['fecha_inicio']),
        activityTypeId: (json['id_tipo_actividad'] as num?)?.toInt(),
        mode: planModeFromDb(json['modalidad'] as String?),
        minParticipants: (json['cupos_minimos'] as num?)?.toInt(),
        maxParticipants: (json['cupos_maximos'] as num?)?.toInt(),
        budgetPerPerson: (json['presupuesto'] as num?)?.toDouble(),
        distanceKm: (json['distancia_km'] as num?)?.toDouble(),
        difficulty: planDifficultyFromDb(json['dificultad'] as String?),
        imagePath: json['imagen'] as String?,
        imageUrl: imageUrl,
        status: planStatusFromDb(json['estado'] as String),
        cancellationReason: json['motivo_cancelacion'] as String?,
        cancelledAt: _date(json['cancelado_en']),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  static DateTime? _date(Object? value) =>
      value == null ? null : DateTime.parse(value as String);

  static Map<String, dynamic> inputJson(PlanInput input) => {
    'titulo': input.title.trim(),
    'descripcion': input.description.trim(),
    'lugar': input.place.trim(),
    'fecha_inicio': input.startsAt?.toUtc().toIso8601String(),
    'id_tipo_actividad': input.activityTypeId,
    'modalidad': input.mode?.dbValue,
    'cupos_minimos': input.minParticipants,
    'cupos_maximos': input.maxParticipants,
    'presupuesto': input.budgetPerPerson,
    'distancia_km': input.distanceKm,
    'dificultad': input.difficulty?.dbValue,
    'imagen': input.imagePath,
  };
}
