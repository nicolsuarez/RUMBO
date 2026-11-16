/// Contrato de Inscripción usado por US-05, US-06, US-07 y US-08.
/// Independiente de Supabase y de las pantallas Flutter.
enum EnrollmentStatus { pending, confirmed, cancelled, rejected }

EnrollmentStatus enrollmentStatusFromDb(String value) => switch (value) {
  'pendiente' => EnrollmentStatus.pending,
  'confirmada' => EnrollmentStatus.confirmed,
  'cancelada' => EnrollmentStatus.cancelled,
  'rechazada' => EnrollmentStatus.rejected,
  _ => throw FormatException('Estado de inscripción desconocido: $value'),
};

class EnrollmentEntity {
  const EnrollmentEntity({
    required this.id,
    required this.userId,
    required this.planId,
    required this.status,
    required this.enrolledAt,
    this.planTitle,
    this.planPlace,
    this.planStartsAt,
  });

  final String id;
  final String userId;
  final String planId;
  final EnrollmentStatus status;
  final DateTime enrolledAt;
  final String? planTitle;
  final String? planPlace;
  final DateTime? planStartsAt;

  bool get isActive =>
      status == EnrollmentStatus.pending || status == EnrollmentStatus.confirmed;
}

class PlanAvailability {
  const PlanAvailability({
    required this.occupied,
    required this.capacity,
    required this.pendingRequests,
  });

  final int occupied;
  final int capacity;
  final int pendingRequests;
  int get remaining => (capacity - occupied).clamp(0, capacity).toInt();
  bool get isFull => occupied >= capacity;
}
