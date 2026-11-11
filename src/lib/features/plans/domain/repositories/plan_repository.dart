import '../entities/activity_type.dart';
import '../entities/plan_entity.dart';
import '../entities/plan_input.dart';

/// Contrato público para Persona 2: UUID, propietario, estado, modalidad y cupos.
abstract class PlanRepository {
  Future<List<PlanEntity>> getPublishedPlans();
  Future<List<PlanEntity>> getOrganizerPlans(String organizerId);
  Future<PlanEntity> getPlanById(String planId);
  Future<List<ActivityType>> getActivityTypes();

  /// create: publish=false -> borrador; true -> publicado.
  Future<PlanEntity> createPlan(PlanInput input, {required bool publish});
  Future<PlanEntity> updatePlan(
    String planId,
    PlanInput input, {
    required bool publish,
  });
  Future<PlanEntity> cancelPlan(String planId);
  Future<PlanEntity> finishPlan(String planId);
  Future<void> deleteDraft(String planId);
}
