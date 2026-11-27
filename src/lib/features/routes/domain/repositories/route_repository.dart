import '../entities/route_entity.dart';

abstract class RouteRepository {
  Future<RouteEntity?> myRouteForPlan(String planId);
  Future<RouteEntity?> myActiveRoute();
  Future<RouteEntity> start(String planId);
  Future<RouteEntity> updateProgress(String routeId, double progress);
  Future<RouteEntity> pause(String routeId);
  Future<RouteEntity> resume(String routeId);
  Future<RouteEntity> finish(String routeId);
}
