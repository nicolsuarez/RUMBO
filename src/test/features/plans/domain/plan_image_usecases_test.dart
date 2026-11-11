import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rumbo/features/plans/domain/entities/activity_type.dart';
import 'package:rumbo/features/plans/domain/entities/plan_entity.dart';
import 'package:rumbo/features/plans/domain/entities/plan_image.dart';
import 'package:rumbo/features/plans/domain/entities/plan_input.dart';
import 'package:rumbo/features/plans/domain/repositories/plan_image_repository.dart';
import 'package:rumbo/features/plans/domain/repositories/plan_repository.dart';
import 'package:rumbo/features/plans/domain/usecases/plan_usecases.dart';

void main() {
  final photo = PlanImage.fromBytes(
    Uint8List.fromList([0xff, 0xd8, 0xff, 0x00]),
  );
  const input = PlanInput(
    title: 'Pance',
    description: 'Caminata',
    place: 'Cali',
  );

  test('creación almacena el nuevo path, no la URL', () async {
    final plans = _FakePlanRepository();
    final images = _FakeImageRepository();

    final created = await CreatePlanUseCase(plans, images)(
      input,
      publish: false,
      newImage: photo,
    );

    expect(created.imagePath, 'usuario/imagen.jpg');
    expect(plans.savedImagePath, 'usuario/imagen.jpg');
    expect(images.deleted, isEmpty);
  });

  test('si falla crear el plan, limpia el archivo subido', () async {
    final plans = _FakePlanRepository()..failCreate = true;
    final images = _FakeImageRepository();

    await expectLater(
      CreatePlanUseCase(plans, images)(input, publish: false, newImage: photo),
      throwsStateError,
    );
    expect(images.deleted, ['usuario/imagen.jpg']);
  });

  test('edición reemplaza imagen y limpia la anterior tras guardar', () async {
    final plans = _FakePlanRepository()
      ..existingImagePath = 'usuario/antigua.png';
    final images = _FakeImageRepository();

    final result = await UpdatePlanUseCase(plans, images)(
      'plan1',
      input,
      publish: false,
      newImage: photo,
    );

    expect(result.imagePath, 'usuario/imagen.jpg');
    expect(images.deleted, ['usuario/antigua.png']);
  });

  test(
    'si falla editar, preserva imagen anterior y elimina solo la nueva',
    () async {
      final plans = _FakePlanRepository()
        ..existingImagePath = 'usuario/antigua.png'
        ..failUpdate = true;
      final images = _FakeImageRepository();

      await expectLater(
        UpdatePlanUseCase(plans, images)(
          'plan1',
          input,
          publish: false,
          newImage: photo,
        ),
        throwsStateError,
      );
      expect(plans.existingImagePath, 'usuario/antigua.png');
      expect(images.deleted, ['usuario/imagen.jpg']);
    },
  );

  test('quitar imagen actualiza plan y limpia almacenamiento', () async {
    final plans = _FakePlanRepository()
      ..existingImagePath = 'usuario/antigua.png';
    final images = _FakeImageRepository();

    final updated = await UpdatePlanUseCase(plans, images)(
      'plan1',
      input,
      publish: false,
      removeImage: true,
    );

    expect(updated.imagePath, isNull);
    expect(images.deleted, ['usuario/antigua.png']);
  });

  test('eliminar borrador borra su foto después de eliminar el plan', () async {
    final plans = _FakePlanRepository()
      ..existingImagePath = 'usuario/antigua.png';
    final images = _FakeImageRepository();

    await DeleteDraftUseCase(plans, images)('plan1');

    expect(plans.wasDeleted, isTrue);
    expect(images.deleted, ['usuario/antigua.png']);
  });
}

class _FakeImageRepository implements PlanImageRepository {
  final deleted = <String>[];

  @override
  Future<String> upload(PlanImage image) async => 'usuario/imagen.jpg';

  @override
  Future<void> delete(String path) async {
    deleted.add(path);
  }

  @override
  String publicUrl(String path) => 'https://example.test/$path';
}

class _FakePlanRepository implements PlanRepository {
  String? existingImagePath;
  String? savedImagePath;
  bool failCreate = false;
  bool failUpdate = false;
  bool wasDeleted = false;

  PlanEntity _entity(String? imagePath) => PlanEntity(
    id: 'plan1',
    organizerId: 'organizador',
    title: 'Pance',
    description: 'Caminata',
    place: 'Cali',
    status: PlanStatus.draft,
    imagePath: imagePath,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  @override
  Future<PlanEntity> createPlan(
    PlanInput input, {
    required bool publish,
  }) async {
    if (failCreate) throw StateError('Error de Postgres');
    savedImagePath = input.imagePath;
    return _entity(savedImagePath);
  }

  @override
  Future<PlanEntity> updatePlan(
    String planId,
    PlanInput input, {
    required bool publish,
  }) async {
    if (failUpdate) throw StateError('Error de Postgres');
    existingImagePath = input.imagePath;
    return _entity(existingImagePath);
  }

  @override
  Future<PlanEntity> getPlanById(String planId) async =>
      _entity(existingImagePath);

  @override
  Future<void> deleteDraft(String planId) async {
    wasDeleted = true;
  }

  @override
  Future<List<PlanEntity>> getPublishedPlans() async => [];
  @override
  Future<List<PlanEntity>> getOrganizerPlans(String organizerId) async => [];
  @override
  Future<List<ActivityType>> getActivityTypes() async => [];
  @override
  Future<PlanEntity> cancelPlan(String planId) async =>
      _entity(existingImagePath);
  @override
  Future<PlanEntity> finishPlan(String planId) async =>
      _entity(existingImagePath);
}
