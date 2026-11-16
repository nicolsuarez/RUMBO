import '../entities/enrollment_entity.dart';
import '../repositories/enrollment_repository.dart';

class EnrollInPlanUseCase {
  const EnrollInPlanUseCase(this.repository);
  final EnrollmentRepository repository;
  Future<void> call(String id) => repository.enroll(id);
}

class GetMyEnrollmentsUseCase {
  const GetMyEnrollmentsUseCase(this.repository);
  final EnrollmentRepository repository;
  Future<List<EnrollmentEntity>> call() => repository.myEnrollments();
}

class CancelEnrollmentUseCase {
  const CancelEnrollmentUseCase(this.repository);
  final EnrollmentRepository repository;
  Future<void> call(String id) => repository.cancel(id);
}

class CheckPlanAvailabilityUseCase {
  const CheckPlanAvailabilityUseCase(this.repository);
  final EnrollmentRepository repository;
  Future<PlanAvailability> call(String id) => repository.availabilityForPlan(id);
}

class GetMyEnrollmentForPlanUseCase {
  const GetMyEnrollmentForPlanUseCase(this.repository);
  final EnrollmentRepository repository;
  Future<EnrollmentEntity?> call(String id) => repository.myEnrollmentForPlan(id);
}

class GetPendingRequestsUseCase {
  const GetPendingRequestsUseCase(this.repository);
  final EnrollmentRepository repository;
  Future<List<EnrollmentEntity>> call(String id) => repository.pendingRequests(id);
}

class ResolveEnrollmentRequestUseCase {
  const ResolveEnrollmentRequestUseCase(this.repository);
  final EnrollmentRepository repository;
  Future<void> call(String id, {required bool approve}) =>
      repository.resolveRequest(id, approve: approve);
}
