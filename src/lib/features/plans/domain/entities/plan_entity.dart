/// Entidad de negocio: no depende de Flutter ni de Supabase.
class PlanEntity {
  const PlanEntity({
    required this.id,
    required this.organizerId,
    required this.title,
    required this.description,
    required this.place,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.startsAt,
    this.activityTypeId,
    this.mode,
    this.minParticipants,
    this.maxParticipants,
    this.budgetPerPerson,
    this.distanceKm,
    this.difficulty,
    this.imagePath,
    this.imageUrl,
    this.cancellationReason,
    this.cancelledAt,
  });

  final String id;
  final String organizerId;
  final String title;
  final String description;
  final String place;
  final PlanStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startsAt;
  final int? activityTypeId;
  final PlanMode? mode;
  final int? minParticipants;
  final int? maxParticipants;
  final double? budgetPerPerson;
  final double? distanceKm;
  final PlanDifficulty? difficulty;
  final String? imagePath;

  /// URL de lectura calculada por la capa data (no se persiste en plan).
  final String? imageUrl;
  final String? cancellationReason;
  final DateTime? cancelledAt;

  bool get isDraft => status == PlanStatus.draft;
  bool get isPublished => status == PlanStatus.published;
}

enum PlanStatus { draft, published, cancelled, finished }

enum PlanMode { public, private }

enum PlanDifficulty { easy, medium, hard }

/// Diccionarios DB -> dominio; no hacen parte de widgets ni DTOs.
extension PlanStatusDb on PlanStatus {
  String get dbValue => switch (this) {
    PlanStatus.draft => 'borrador',
    PlanStatus.published => 'publicado',
    PlanStatus.cancelled => 'cancelado',
    PlanStatus.finished => 'finalizado',
  };
}

extension PlanModeDb on PlanMode {
  String get dbValue => switch (this) {
    PlanMode.public => 'publico',
    PlanMode.private => 'privado',
  };
}

extension PlanDifficultyDb on PlanDifficulty {
  String get dbValue => switch (this) {
    PlanDifficulty.easy => 'suave',
    PlanDifficulty.medium => 'media',
    PlanDifficulty.hard => 'exigente',
  };
}

PlanStatus planStatusFromDb(String value) => switch (value) {
  'borrador' => PlanStatus.draft,
  'publicado' => PlanStatus.published,
  'cancelado' => PlanStatus.cancelled,
  'finalizado' => PlanStatus.finished,
  _ => throw FormatException('Estado desconocido: $value'),
};

PlanMode? planModeFromDb(String? value) => switch (value) {
  null => null,
  'publico' => PlanMode.public,
  'privado' => PlanMode.private,
  _ => throw FormatException('Modalidad desconocida: $value'),
};

PlanDifficulty? planDifficultyFromDb(String? value) => switch (value) {
  null => null,
  'suave' => PlanDifficulty.easy,
  'media' => PlanDifficulty.medium,
  'exigente' => PlanDifficulty.hard,
  _ => throw FormatException('Dificultad desconocida: $value'),
};
