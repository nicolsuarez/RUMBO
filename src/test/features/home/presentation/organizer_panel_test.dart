
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:rumbo/features/home/presentation/screens/organizer_panel.dart';
import 'package:rumbo/features/plans/domain/entities/activity_type.dart';
import 'package:rumbo/features/plans/domain/entities/plan_entity.dart';
import 'package:rumbo/features/plans/domain/entities/plan_image.dart';
import 'package:rumbo/features/plans/domain/entities/plan_input.dart';
import 'package:rumbo/features/plans/domain/repositories/plan_repository.dart';
import 'package:rumbo/features/plans/domain/repositories/plan_image_repository.dart';
import 'package:rumbo/features/plans/domain/usecases/plan_usecases.dart';
import 'package:rumbo/features/plans/presentation/bloc/plans_bloc.dart';

void main() {
  group('OrganizerPanel', () {
    late PlansBloc bloc;

    setUp(() {
      final repository = _FakePlanRepository();
      final images = _FakePlanImageRepository();

      bloc = PlansBloc(
        getPublishedPlans: GetPublishedPlansUseCase(repository),
        getOrganizerPlans: GetOrganizerPlansUseCase(repository),
        getActivityTypes: GetActivityTypesUseCase(repository),
        createPlan: CreatePlanUseCase(repository, images),
        updatePlan: UpdatePlanUseCase(repository, images),
        cancelPlan: CancelPlanUseCase(repository),
        finishPlan: FinishPlanUseCase(repository),
        deleteDraft: DeleteDraftUseCase(repository, images),
      );
    });

    tearDown(() async {
      await bloc.close();
    });

    Widget createWidget({
      required VoidCallback onCreate,
      required VoidCallback onMyPlans,
    }) {
      return MaterialApp(
        home: BlocProvider.value(
          value: bloc,
          child: Scaffold(
            body: OrganizerPanel(
              onCreate: onCreate,
              onMyPlans: onMyPlans,
            ),
          ),
        ),
      );
    }

    testWidgets(
      'muestra un mensaje cuando el organizador no tiene planes publicados',
      (tester) async {
        await tester.pumpWidget(
          createWidget(
            onCreate: () {},
            onMyPlans: () {},
          ),
        );

        expect(
          find.text('Todavía no has publicado ningún plan.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'ejecuta la acción para crear un plan',
      (tester) async {
        var createPressed = false;

        await tester.pumpWidget(
          createWidget(
            onCreate: () => createPressed = true,
            onMyPlans: () {},
          ),
        );

        await tester.tap(find.text('Crear un plan nuevo'));
        await tester.pump();

        expect(createPressed, isTrue);
      },
    );

    testWidgets(
      'ejecuta la acción para gestionar todos los planes',
      (tester) async {
        var myPlansPressed = false;

        await tester.pumpWidget(
          createWidget(
            onCreate: () {},
            onMyPlans: () => myPlansPressed = true,
          ),
        );

        await tester.tap(find.text('Gestionar todos mis planes'));
        await tester.pump();

        expect(myPlansPressed, isTrue);
      },
    );
  });
}

class _FakePlanRepository implements PlanRepository {
  @override
  Future<List<PlanEntity>> getPublishedPlans() async => [];

  @override
  Future<List<PlanEntity>> getOrganizerPlans(String organizerId) async => [];

  @override
  Future<List<ActivityType>> getActivityTypes() async => [];

  @override
  Future<PlanEntity> getPlanById(String planId) async {
    throw UnimplementedError();
  }

  @override
  Future<PlanEntity> createPlan(
    PlanInput input, {
    required bool publish,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<PlanEntity> updatePlan(
    String planId,
    PlanInput input, {
    required bool publish,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<PlanEntity> cancelPlan(String planId) async {
    throw UnimplementedError();
  }

  @override
  Future<PlanEntity> finishPlan(String planId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteDraft(String planId) async {
    throw UnimplementedError();
  }
}

class _FakePlanImageRepository implements PlanImageRepository {
  @override
  Future<String> upload(PlanImage image) async => 'test/image.jpg';

  @override
  Future<void> delete(String path) async {}

  @override
  String publicUrl(String path) => 'https://example.com/$path';
}
