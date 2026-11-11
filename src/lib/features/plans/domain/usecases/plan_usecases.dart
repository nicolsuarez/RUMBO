import '../entities/activity_type.dart';
import '../entities/plan_entity.dart';
import '../entities/plan_image.dart';
import '../entities/plan_input.dart';
import '../repositories/plan_image_repository.dart';
import '../repositories/plan_repository.dart';

class GetPublishedPlansUseCase {
  const GetPublishedPlansUseCase(this.repository);
  final PlanRepository repository;
  Future<List<PlanEntity>> call() => repository.getPublishedPlans();
}

class GetOrganizerPlansUseCase {
  const GetOrganizerPlansUseCase(this.repository);
  final PlanRepository repository;
  Future<List<PlanEntity>> call(String organizerId) =>
      repository.getOrganizerPlans(organizerId);
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

/// La foto se sube únicamente al guardar. Si falla PostgreSQL, se intenta
/// retirar el archivo recién creado para evitar objetos huérfanos.
class CreatePlanUseCase {
  const CreatePlanUseCase(this.repository, this.images);
  final PlanRepository repository;
  final PlanImageRepository images;

  Future<PlanEntity> call(
    PlanInput input, {
    required bool publish,
    PlanImage? newImage,
  }) async {
    input.validate(publish: publish);
    final path = newImage == null ? null : await images.upload(newImage);
    try {
      return await repository.createPlan(
        input.withImagePath(path),
        publish: publish,
      );
    } catch (_) {
      if (path != null) await _deleteQuietly(images, path);
      rethrow;
    }
  }
}

/// Actualizar foto: subir una nueva ruta, guardar en PostgreSQL y solo entonces
/// intentar borrar la anterior. No usamos upsert ni sobrescribimos imágenes.
class UpdatePlanUseCase {
  const UpdatePlanUseCase(this.repository, this.images);
  final PlanRepository repository;
  final PlanImageRepository images;

  Future<PlanEntity> call(
    String id,
    PlanInput input, {
    required bool publish,
    PlanImage? newImage,
    bool removeImage = false,
  }) async {
    input.validate(publish: publish);
    final before = await repository.getPlanById(id);
    final path = newImage == null ? null : await images.upload(newImage);
    final desired = path ?? (removeImage ? null : before.imagePath);
    try {
      final saved = await repository.updatePlan(
        id,
        input.withImagePath(desired),
        publish: publish,
      );
      if (before.imagePath != null && before.imagePath != desired) {
        await _deleteQuietly(images, before.imagePath!);
      }
      return saved;
    } catch (_) {
      if (path != null) await _deleteQuietly(images, path);
      rethrow;
    }
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
  const DeleteDraftUseCase(this.repository, this.images);
  final PlanRepository repository;
  final PlanImageRepository images;

  Future<void> call(String id) async {
    final plan = await repository.getPlanById(id);
    await repository.deleteDraft(id);
    if (plan.imagePath != null) {
      await _deleteQuietly(images, plan.imagePath!);
    }
  }
}

/// Storage y Postgres no comparten una transacción distribuida. Un fallo en
/// la limpieza no debe deshacer un guardado válido; se documenta este límite.
Future<void> _deleteQuietly(PlanImageRepository images, String path) async {
  try {
    await images.delete(path);
  } catch (_) {
    // La limpieza huérfana se podrá gestionar de manera administrativa.
  }
}
