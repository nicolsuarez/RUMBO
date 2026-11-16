import '../entities/enrollment_entity.dart';

abstract class EnrollmentRepository {
  Future<List<EnrollmentEntity>> myEnrollments();
  Future<EnrollmentEntity?> myEnrollmentForPlan(String planId);
  Future<PlanAvailability> availabilityForPlan(String planId);
  Future<void> enroll(String planId);
  Future<void> cancel(String planId);
  Future<List<EnrollmentEntity>> pendingRequests(String planId);
  Future<void> resolveRequest(String enrollmentId, {required bool approve});
}
