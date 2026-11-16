import '../../domain/entities/enrollment_entity.dart';
import '../../domain/repositories/enrollment_repository.dart';
import '../datasources/supabase_enrollment_data_source.dart';
import '../models/enrollment_model.dart';

class SupabaseEnrollmentRepository implements EnrollmentRepository {
  const SupabaseEnrollmentRepository(this.dataSource);
  final SupabaseEnrollmentDataSource dataSource;

  @override
  Future<List<EnrollmentEntity>> myEnrollments() async =>
      (await dataSource.myEnrollments()).map(EnrollmentModel.fromJson).toList();

  @override
  Future<EnrollmentEntity?> myEnrollmentForPlan(String id) async {
    final data = await dataSource.myEnrollmentForPlan(id);
    return data == null ? null : EnrollmentModel.fromJson(data);
  }

  @override
  Future<PlanAvailability> availabilityForPlan(String id) async =>
      EnrollmentModel.availabilityFromJson(
        await dataSource.availabilityForPlan(id),
      );

  @override
  Future<void> enroll(String id) => dataSource.enroll(id);

  @override
  Future<void> cancel(String id) => dataSource.cancel(id);

  @override
  Future<List<EnrollmentEntity>> pendingRequests(String id) async =>
      (await dataSource.pendingRequests(id))
          .map(EnrollmentModel.fromJson)
          .toList();

  @override
  Future<void> resolveRequest(String id, {required bool approve}) =>
      dataSource.resolveRequest(id, approve: approve);
}
