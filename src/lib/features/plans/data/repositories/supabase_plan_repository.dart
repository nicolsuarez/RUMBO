import '../../domain/entities/activity_type.dart';
import '../../domain/entities/plan_entity.dart';
import '../../domain/entities/plan_input.dart';
import '../../domain/repositories/plan_image_repository.dart';
import '../../domain/repositories/plan_repository.dart';
import '../datasources/supabase_plan_data_source.dart';
import '../models/plan_model.dart';

class SupabasePlanRepository implements PlanRepository {
  const SupabasePlanRepository(this.source, this.images);
  final SupabasePlanDataSource source;
  final PlanImageRepository images;

  PlanEntity _fromJson(Map<String, dynamic> row) {
    final imagePath = row['imagen'] as String?;
    String? url;
    if (imagePath != null && imagePath.isNotEmpty) {
      // Compatibilidad de lectura con antiguos valores URL (si existieran).
      url = imagePath.startsWith('https://') || imagePath.startsWith('http://')
          ? imagePath
          : images.publicUrl(imagePath);
    }
    return PlanModel.fromJson(row, imageUrl: url);
  }

  @override
  Future<List<PlanEntity>> getPublishedPlans() async =>
      (await source.publishedPlans()).map(_fromJson).toList();

  @override
  Future<List<PlanEntity>> getOrganizerPlans(String organizerId) async =>
      (await source.organizerPlans(organizerId)).map(_fromJson).toList();

  @override
  Future<PlanEntity> getPlanById(String planId) async =>
      _fromJson(await source.planById(planId));

  @override
  Future<List<ActivityType>> getActivityTypes() async =>
      (await source.activities())
          .map(
            (row) => ActivityType(
              id: (row['id_tipo_actividad'] as num).toInt(),
              name: row['nombre'] as String,
            ),
          )
          .toList();

  @override
  Future<PlanEntity> createPlan(
    PlanInput input, {
    required bool publish,
  }) async {
    final json = PlanModel.inputJson(input);
    json['estado'] = publish ? 'publicado' : 'borrador';
    return _fromJson(await source.insert(json));
  }

  @override
  Future<PlanEntity> updatePlan(
    String planId,
    PlanInput input, {
    required bool publish,
  }) async {
    final json = PlanModel.inputJson(input);
    json['estado'] = publish ? 'publicado' : 'borrador';
    return _fromJson(await source.update(planId, json));
  }

  @override
  Future<PlanEntity> cancelPlan(String id) async =>
      _fromJson(await source.update(id, {'estado': 'cancelado'}));

  @override
  Future<PlanEntity> finishPlan(String id) async =>
      _fromJson(await source.update(id, {'estado': 'finalizado'}));

  @override
  Future<void> deleteDraft(String id) => source.delete(id);
}
