import 'plan_entity.dart';

/// Valores editables: admite datos parciales para borradores.
/// id_organizador se obtiene de la sesión, nunca del formulario.
class PlanInput {
  const PlanInput({
    required this.title,
    required this.description,
    required this.place,
    this.startsAt,
    this.activityTypeId,
    this.mode,
    this.minParticipants,
    this.maxParticipants,
    this.budgetPerPerson,
    this.distanceKm,
    this.difficulty,
    this.imagePath,
  });

  final String title;
  final String description;
  final String place;
  final DateTime? startsAt;
  final int? activityTypeId;
  final PlanMode? mode;
  final int? minParticipants;
  final int? maxParticipants;
  final double? budgetPerPerson;
  final double? distanceKm;
  final PlanDifficulty? difficulty;
  final String? imagePath;

  PlanInput withImagePath(String? path) => PlanInput(
    title: title,
    description: description,
    place: place,
    startsAt: startsAt,
    activityTypeId: activityTypeId,
    mode: mode,
    minParticipants: minParticipants,
    maxParticipants: maxParticipants,
    budgetPerPerson: budgetPerPerson,
    distanceKm: distanceKm,
    difficulty: difficulty,
    imagePath: path,
  );

  /// Evita errores comunes antes de escribir a PostgreSQL.
  /// La BD también protege la integridad mediante CHECK/trigger/RLS.
  void validate({required bool publish}) {
    if (title.trim().isEmpty ||
        description.trim().isEmpty ||
        place.trim().isEmpty) {
      throw ArgumentError('Título, descripción y lugar son obligatorios.');
    }
    if (title.trim().length > 120 || place.trim().length > 150) {
      throw ArgumentError('Título o lugar exceden la longitud permitida.');
    }
    if (minParticipants != null && minParticipants! <= 0 ||
        maxParticipants != null && maxParticipants! <= 0) {
      throw ArgumentError('Los cupos deben ser mayores que cero.');
    }
    if (minParticipants != null &&
        maxParticipants != null &&
        minParticipants! > maxParticipants!) {
      throw ArgumentError('Los cupos mínimos no pueden superar los máximos.');
    }
    if (budgetPerPerson != null && budgetPerPerson! < 0) {
      throw ArgumentError('El presupuesto por persona no puede ser negativo.');
    }
    if (distanceKm != null && distanceKm! < 0) {
      throw ArgumentError('La distancia no puede ser negativa.');
    }
    if (publish) {
      if (startsAt == null ||
          activityTypeId == null ||
          mode == null ||
          minParticipants == null ||
          maxParticipants == null ||
          budgetPerPerson == null) {
        throw ArgumentError(
          'Completa fecha, actividad, modalidad, cupos y presupuesto para publicar.',
        );
      }
      if (!startsAt!.isAfter(DateTime.now())) {
        throw ArgumentError('La fecha de inicio debe estar en el futuro.');
      }
    }
  }
}
