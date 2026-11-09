import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/plans/data/datasources/supabase_plan_data_source.dart';
import '../../features/plans/data/datasources/supabase_plan_image_data_source.dart';
import '../../features/plans/data/repositories/supabase_plan_repository.dart';
import '../../features/plans/data/repositories/supabase_plan_image_repository.dart';
import '../../features/plans/domain/repositories/plan_repository.dart';
import '../../features/plans/domain/repositories/plan_image_repository.dart';
import '../../features/plans/domain/usecases/plan_usecases.dart';
import '../../features/plans/presentation/bloc/plans_bloc.dart';

/// DI incremental: solo Plans. Auth continúa con la composición existente.
final GetIt locator = GetIt.instance;

void registerPlansDependencies(SupabaseClient client) {
  if (locator.isRegistered<PlanRepository>()) return;
  if (!locator.isRegistered<SupabaseClient>()) {
    locator.registerSingleton<SupabaseClient>(client);
  }
  locator.registerLazySingleton<SupabasePlanDataSource>(
    () => SupabasePlanDataSource(locator<SupabaseClient>()),
  );
  locator.registerLazySingleton<SupabasePlanImageDataSource>(
    () => SupabasePlanImageDataSource(locator<SupabaseClient>()),
  );
  locator.registerLazySingleton<PlanImageRepository>(
    () => SupabasePlanImageRepository(locator<SupabasePlanImageDataSource>()),
  );
  locator.registerLazySingleton<PlanRepository>(
    () => SupabasePlanRepository(
      locator<SupabasePlanDataSource>(),
      locator<PlanImageRepository>(),
    ),
  );
  locator.registerLazySingleton(
    () => GetPublishedPlansUseCase(locator<PlanRepository>()),
  );
  locator.registerLazySingleton(
    () => GetOrganizerPlansUseCase(locator<PlanRepository>()),
  );
  locator.registerLazySingleton(
    () => GetActivityTypesUseCase(locator<PlanRepository>()),
  );
  locator.registerLazySingleton(
    () => CreatePlanUseCase(
      locator<PlanRepository>(),
      locator<PlanImageRepository>(),
    ),
  );
  locator.registerLazySingleton(
    () => UpdatePlanUseCase(
      locator<PlanRepository>(),
      locator<PlanImageRepository>(),
    ),
  );
  locator.registerLazySingleton(
    () => CancelPlanUseCase(locator<PlanRepository>()),
  );
  locator.registerLazySingleton(
    () => FinishPlanUseCase(locator<PlanRepository>()),
  );
  locator.registerLazySingleton(
    () => DeleteDraftUseCase(
      locator<PlanRepository>(),
      locator<PlanImageRepository>(),
    ),
  );
  locator.registerFactory(
    () => PlansBloc(
      getPublishedPlans: locator<GetPublishedPlansUseCase>(),
      getOrganizerPlans: locator<GetOrganizerPlansUseCase>(),
      getActivityTypes: locator<GetActivityTypesUseCase>(),
      createPlan: locator<CreatePlanUseCase>(),
      updatePlan: locator<UpdatePlanUseCase>(),
      cancelPlan: locator<CancelPlanUseCase>(),
      finishPlan: locator<FinishPlanUseCase>(),
      deleteDraft: locator<DeleteDraftUseCase>(),
    ),
  );
}
