import '../entities/route_entity.dart';
import '../repositories/route_repository.dart';

class GetMyRouteForPlanUseCase {
  const GetMyRouteForPlanUseCase(this.repository);
  final RouteRepository repository;
  Future<RouteEntity?> call(String planId) => repository.myRouteForPlan(planId);
}

/// Recupera el único recorrido activo o pausado del usuario.
class GetMyActiveRouteUseCase {
  const GetMyActiveRouteUseCase(this.repository);
  final RouteRepository repository;
  Future<RouteEntity?> call() => repository.myActiveRoute();
}

class StartRouteUseCase {
  const StartRouteUseCase(this.repository);
  final RouteRepository repository;
  Future<RouteEntity> call(String planId) => repository.start(planId);
}

class UpdateRouteProgressUseCase {
  const UpdateRouteProgressUseCase(this.repository);
  final RouteRepository repository;

  Future<RouteEntity> call(String routeId, double progress) async {
    if (!progress.isFinite || progress < 0 || progress > 100) {
      throw ArgumentError.value(progress, 'progress', 'Porcentaje inválido');
    }
    return repository.updateProgress(routeId, progress);
  }
}

class PauseRouteUseCase {
  const PauseRouteUseCase(this.repository);
  final RouteRepository repository;
  Future<RouteEntity> call(String routeId) => repository.pause(routeId);
}

class ResumeRouteUseCase {
  const ResumeRouteUseCase(this.repository);
  final RouteRepository repository;
  Future<RouteEntity> call(String routeId) => repository.resume(routeId);
}

class FinishRouteUseCase {
  const FinishRouteUseCase(this.repository);
  final RouteRepository repository;
  Future<RouteEntity> call(String routeId) => repository.finish(routeId);
}
