import 'package:flutter_test/flutter_test.dart';
import 'package:rumbo/features/routes/domain/entities/route_entity.dart';
import 'package:rumbo/features/routes/domain/repositories/route_repository.dart';
import 'package:rumbo/features/routes/domain/usecases/route_usecases.dart';

class _FakeRepository implements RouteRepository {
  String? operation;
  String? argument;
  double? progressArgument;
  RouteEntity? result;
  Object? error;

  Future<RouteEntity> _call(String name, String id) async {
    operation = name;
    argument = id;
    final failure = error;
    if (failure != null) throw failure;
    return result!;
  }

  @override
  Future<RouteEntity?> myRouteForPlan(String planId) async {
    operation = 'plan';
    argument = planId;
    return result;
  }

  @override
  Future<RouteEntity?> myActiveRoute() async {
    operation = 'active';
    return result;
  }

  @override
  Future<RouteEntity> start(String planId) => _call('start', planId);
  @override
  Future<RouteEntity> updateProgress(String routeId, double progress) {
    progressArgument = progress;
    return _call('advance', routeId);
  }

  @override
  Future<RouteEntity> pause(String routeId) => _call('pause', routeId);
  @override
  Future<RouteEntity> resume(String routeId) => _call('resume', routeId);
  @override
  Future<RouteEntity> finish(String routeId) => _call('finish', routeId);
}

void main() {
  late _FakeRepository repo;
  final persisted = RouteEntity(
    id: 'route-id',
    enrollmentId: 'enrollment-id',
    userId: 'user-id',
    planId: 'plan-id',
    startedAt: DateTime.utc(2026, 11, 26),
    status: RouteStatus.active,
    progress: 37.5,
    distanceKm: 1.5,
  );
  setUp(() => repo = _FakeRepository()..result = persisted);

  test(
    'inicio usa el identificador real del plan y devuelve la fila',
    () async {
      expect(await StartRouteUseCase(repo)('plan-id'), same(persisted));
      expect(repo.operation, 'start');
      expect(repo.argument, 'plan-id');
    },
  );

  test('consulta por plan y recupera un recorrido en curso', () async {
    expect(await GetMyRouteForPlanUseCase(repo)('plan-id'), same(persisted));
    expect(repo.argument, 'plan-id');
    expect(await GetMyActiveRouteUseCase(repo)(), same(persisted));
    expect(repo.operation, 'active');
    repo.result = null;
    expect(await GetMyActiveRouteUseCase(repo)(), isNull);
  });

  test('envía porcentaje absoluto y conserva respuesta del servidor', () async {
    expect(
      await UpdateRouteProgressUseCase(repo)('route-id', 37.5),
      same(persisted),
    );
    expect(repo.operation, 'advance');
    expect(repo.argument, 'route-id');
    expect(repo.progressArgument, 37.5);
  });

  test('rechaza progreso inválido antes de llamar al repositorio', () async {
    final useCase = UpdateRouteProgressUseCase(repo);
    for (final value in [-1.0, 101.0, double.nan, double.infinity]) {
      await expectLater(useCase('route-id', value), throwsArgumentError);
    }
    expect(repo.operation, isNull);
  });

  test('pausa, reanudación y cierre delegan al repositorio', () async {
    expect(await PauseRouteUseCase(repo)('route-id'), same(persisted));
    expect(repo.operation, 'pause');
    expect(await ResumeRouteUseCase(repo)('route-id'), same(persisted));
    expect(repo.operation, 'resume');
    expect(await FinishRouteUseCase(repo)('route-id'), same(persisted));
    expect(repo.operation, 'finish');
    expect(repo.argument, 'route-id');
  });

  test('un rechazo del backend se propaga sin simular éxito', () async {
    final error = StateError('Necesitas una inscripción confirmada');
    repo.error = error;
    await expectLater(StartRouteUseCase(repo)('plan-id'), throwsA(same(error)));
  });
}
