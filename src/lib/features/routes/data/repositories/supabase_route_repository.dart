import '../../domain/entities/route_entity.dart';
import '../../domain/repositories/route_repository.dart';
import '../datasources/supabase_route_data_source.dart';
import '../models/route_model.dart';

class SupabaseRouteRepository implements RouteRepository {
  const SupabaseRouteRepository(this.dataSource);
  final SupabaseRouteDataSource dataSource;

  @override
  Future<RouteEntity?> myRouteForPlan(String planId) async {
    final data = await dataSource.myRouteForPlan(planId);
    return data == null ? null : RouteModel.fromJson(data);
  }

  @override
  Future<RouteEntity?> myActiveRoute() async {
    final data = await dataSource.myActiveRoute();
    return data == null ? null : RouteModel.fromJson(data);
  }

  @override
  Future<RouteEntity> start(String planId) async =>
      RouteModel.fromJson(await dataSource.start(planId));

  @override
  Future<RouteEntity> updateProgress(String routeId, double progress) async =>
      RouteModel.fromJson(await dataSource.updateProgress(routeId, progress));

  @override
  Future<RouteEntity> pause(String routeId) async =>
      RouteModel.fromJson(await dataSource.pause(routeId));

  @override
  Future<RouteEntity> resume(String routeId) async =>
      RouteModel.fromJson(await dataSource.resume(routeId));

  @override
  Future<RouteEntity> finish(String routeId) async =>
      RouteModel.fromJson(await dataSource.finish(routeId));
}
