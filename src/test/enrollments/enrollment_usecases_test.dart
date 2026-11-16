import 'package:flutter_test/flutter_test.dart';
import 'package:rumbo/features/enrollments/domain/entities/enrollment_entity.dart';
import 'package:rumbo/features/enrollments/domain/repositories/enrollment_repository.dart';
import 'package:rumbo/features/enrollments/domain/usecases/enrollment_usecases.dart';
import 'package:rumbo/features/enrollments/presentation/bloc/enrollments_bloc.dart';

/// Pruebas unitarias offline del contrato y los casos de uso.
/// Concurrencia, roles y RLS deben probarse también contra PostgreSQL/Supabase.
class FakeEnrollments implements EnrollmentRepository {
  final Map<String, EnrollmentEntity> records = {};
  int capacity = 1;

  @override
  Future<void> enroll(String planId) async {
    final current = records[planId];
    if (current?.isActive == true) throw StateError('Inscripción duplicada');
    if (records.values.where((e) => e.status == EnrollmentStatus.confirmed)
            .length >= capacity) {
      throw StateError('Sin cupos');
    }
    records[planId] = EnrollmentEntity(
      id: 'enrollment-1',
      userId: 'user-1',
      planId: planId,
      status: EnrollmentStatus.confirmed,
      enrolledAt: DateTime.utc(2026, 11, 15),
      planTitle: 'Ruta de prueba',
    );
  }

  @override
  Future<void> cancel(String planId) async {
    final old = records[planId];
    if (old == null || !old.isActive) throw StateError('No inscrito');
    records[planId] = EnrollmentEntity(
      id: old.id,
      userId: old.userId,
      planId: planId,
      status: EnrollmentStatus.cancelled,
      enrolledAt: old.enrolledAt,
      planTitle: old.planTitle,
    );
  }

  @override
  Future<List<EnrollmentEntity>> myEnrollments() async => records.values.toList();

  @override
  Future<EnrollmentEntity?> myEnrollmentForPlan(String planId) async =>
      records[planId];

  @override
  Future<PlanAvailability> availabilityForPlan(String planId) async =>
      PlanAvailability(
        occupied: records.values.where((e) =>
          e.status == EnrollmentStatus.confirmed).length,
        capacity: capacity,
        pendingRequests: 0,
      );

  @override
  Future<List<EnrollmentEntity>> pendingRequests(String planId) async => [];

  @override
  Future<void> resolveRequest(String enrollmentId, {required bool approve}) async {}
}

EnrollmentsBloc blocFor(FakeEnrollments repo) => EnrollmentsBloc(
  enrollInPlan: EnrollInPlanUseCase(repo),
  getMyEnrollments: GetMyEnrollmentsUseCase(repo),
  cancelEnrollment: CancelEnrollmentUseCase(repo),
  checkPlanAvailability: CheckPlanAvailabilityUseCase(repo),
  getMyEnrollmentForPlan: GetMyEnrollmentForPlanUseCase(repo),
  getPendingRequests: GetPendingRequestsUseCase(repo),
  resolveEnrollmentRequest: ResolveEnrollmentRequestUseCase(repo),
);

void main() {
  group('Persona 2 — US-05 a US-08', () {
    late FakeEnrollments repo;
    setUp(() => repo = FakeEnrollments());

    test('US-05: inscribirse genera inscripción confirmada', () async {
      await EnrollInPlanUseCase(repo)('plan-1');
      final item = await GetMyEnrollmentForPlanUseCase(repo)('plan-1');
      expect(item?.status, EnrollmentStatus.confirmed);
    });

    test('US-06: consultar Mis planes devuelve las inscripciones', () async {
      await EnrollInPlanUseCase(repo)('plan-1');
      final mine = await GetMyEnrollmentsUseCase(repo)();
      expect(mine.single.planTitle, 'Ruta de prueba');
    });

    test('US-07: cancelar cambia estado y libera el cupo', () async {
      await EnrollInPlanUseCase(repo)('plan-1');
      await CancelEnrollmentUseCase(repo)('plan-1');
      expect((await GetMyEnrollmentsUseCase(repo)()).single.status,
          EnrollmentStatus.cancelled);
      expect((await CheckPlanAvailabilityUseCase(repo)('plan-1')).remaining, 1);
    });

    test('US-08: no se admite una segunda inscripción activa', () async {
      await EnrollInPlanUseCase(repo)('plan-1');
      await expectLater(EnrollInPlanUseCase(repo)('plan-1'), throwsStateError);
    });

    test('US-08: se rechaza una reserva si el cupo está completo', () async {
      await EnrollInPlanUseCase(repo)('plan-1');
      await expectLater(EnrollInPlanUseCase(repo)('plan-2'), throwsStateError);
    });

    test('BLoC: inscribir y cancelar actualiza Mis planes', () async {
      final bloc = blocFor(repo);
      try {
        bloc.add(const EnrollmentsJoinRequested('plan-1'));
        final joined = await bloc.stream.firstWhere(
          (state) => state.message != null && state.mine.isNotEmpty,
        );
        expect(joined.mine.single.status, EnrollmentStatus.confirmed);

        bloc.add(const EnrollmentsCancelRequested('plan-1'));
        final cancelled = await bloc.stream.firstWhere(
          (state) => state.message == 'Inscripción cancelada.',
        );
        expect(cancelled.mine.single.status, EnrollmentStatus.cancelled);
      } finally {
        await bloc.close();
      }
    });

    test('el dominio interpreta los estados exactos de PostgreSQL', () {
      expect(enrollmentStatusFromDb('pendiente'), EnrollmentStatus.pending);
      expect(enrollmentStatusFromDb('confirmada'), EnrollmentStatus.confirmed);
      expect(enrollmentStatusFromDb('cancelada'), EnrollmentStatus.cancelled);
      expect(enrollmentStatusFromDb('rechazada'), EnrollmentStatus.rejected);
      expect(() => enrollmentStatusFromDb('desconocido'), throwsFormatException);
    });
  });
}
