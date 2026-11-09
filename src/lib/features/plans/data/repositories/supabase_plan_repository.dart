import '../../domain/entities/activity_type.dart';
import '../../domain/entities/plan_entity.dart';
import '../../domain/entities/plan_input.dart';
import '../../domain/repositories/plan_repository.dart';
import '../datasources/supabase_plan_data_source.dart';
import '../models/plan_model.dart';

class SupabasePlanRepository implements PlanRepository {
  const SupabasePlanRepository(this.source);
  final SupabasePlanDataSource source;

  @override
  Future<List<PlanEntity>> getPublishedPlans() async =>
      (await source.publishedPlans()).map(PlanModel.fromJson).toList();

  @override
  Future<List<PlanEntity>> getOrganizerPlans(String organizerId) async =>
      (await source.organizerPlans(organizerId)).map(PlanModel.fromJson).toList();

  @override
  Future<PlanEntity> getPlanById(String planId) async =>
      PlanModel.fromJson(await source.planById(planId));

  @override
  Future<List<ActivityType>> getActivityTypes() async =>
      (await source.activities())
          .map((row) => ActivityType(
            id: (row['id_tipo_actividad'] as num).toInt(),
            name: row['nombre'] as String,
          ))
          .toList();

  @override
  Future<PlanEntity> createPlan(PlanInput input, {required bool publish}) async {
    final json = PlanModel.inputJson(input);
    json['estado'] = publish ? 'publicado' : 'borrador';
    return PlanModel.fromJson(await source.insert(json));
  }

  @override
  Future<PlanEntity> updatePlan(String planId, PlanInput input, {required bool publish}) async {
    final json = PlanModel.inputJson(input);
    json['estado'] = publish ? 'publicado' : 'borrador';
    return PlanModel.fromJson(await source.update(planId, json));
  }

  @override
  Future<PlanEntity> cancelPlan(String id) async => PlanModel.fromJson(
    await source.update(id, {'estado': 'cancelado'}),
  );

  @override
  Future<PlanEntity> finishPlan(String id) async => PlanModel.fromJson(
    await source.update(id, {'estado': 'finalizado'}),
  );

  @override
  Future<void> deleteDraft(String id) => source.delete(id);
}
