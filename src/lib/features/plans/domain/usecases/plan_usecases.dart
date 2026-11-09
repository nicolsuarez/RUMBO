import '../entities/activity_type.dart';
import '../entities/plan_entity.dart';
import '../entities/plan_input.dart';
import '../repositories/plan_repository.dart';

class GetPublishedPlansUseCase {
  const GetPublishedPlansUseCase(this.repository);
  final PlanRepository repository;
  Future<List<PlanEntity>> call() => repository.getPublishedPlans();
}

class GetOrganizerPlansUseCase {
  const GetOrganizerPlansUseCase(this.repository);
  final PlanRepository repository;
  Future<List<PlanEntity>> call(String organizerId) => repository.getOrganizerPlans(organizerId);
}

class GetPlanByIdUseCase {
  const GetPlanByIdUseCase(this.repository);
  final PlanRepository repository;
  Future<PlanEntity> call(String id) => repository.getPlanById(id);
}

class GetActivityTypesUseCase {
  const GetActivityTypesUseCase(this.repository);
  final PlanRepository repository;
  Future<List<ActivityType>> call() => repository.getActivityTypes();
}

class CreatePlanUseCase {
  const CreatePlanUseCase(this.repository);
  final PlanRepository repository;
  Future<PlanEntity> call(PlanInput input, {required bool publish}) {
    input.validate(publish: publish);
    return repository.createPlan(input, publish: publish);
  }
}

class UpdatePlanUseCase {
  const UpdatePlanUseCase(this.repository);
  final PlanRepository repository;
  Future<PlanEntity> call(String id, PlanInput input, {required bool publish}) {
    input.validate(publish: publish);
    return repository.updatePlan(id, input, publish: publish);
  }
}

class CancelPlanUseCase {
  const CancelPlanUseCase(this.repository);
  final PlanRepository repository;
  Future<PlanEntity> call(String id) => repository.cancelPlan(id);
}

class FinishPlanUseCase {
  const FinishPlanUseCase(this.repository);
  final PlanRepository repository;
  Future<PlanEntity> call(String id) => repository.finishPlan(id);
}

class DeleteDraftUseCase {
  const DeleteDraftUseCase(this.repository);
  final PlanRepository repository;
  Future<void> call(String id) => repository.deleteDraft(id);
}
