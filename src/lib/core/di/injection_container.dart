import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/data/datasources/supabase_auth_data_source.dart';
import '../../features/auth/data/repositories/supabase_auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/auth/domain/usecases/check_username_availability_usecase.dart';
import '../../features/auth/domain/usecases/session_usecases.dart';
import '../../features/auth/presentation/bloc/auth/auth_bloc.dart';
import '../../features/auth/presentation/bloc/login/login_bloc.dart';
import '../../features/auth/presentation/bloc/register/register_bloc.dart';

import '../../features/plans/data/datasources/supabase_plan_data_source.dart';
import '../../features/plans/data/datasources/supabase_plan_image_data_source.dart';
import '../../features/plans/data/repositories/supabase_plan_repository.dart';
import '../../features/plans/data/repositories/supabase_plan_image_repository.dart';
import '../../features/plans/domain/repositories/plan_repository.dart';
import '../../features/plans/domain/repositories/plan_image_repository.dart';
import '../../features/plans/domain/usecases/plan_usecases.dart';
import '../../features/plans/presentation/bloc/plans_bloc.dart';

import '../../features/enrollments/data/datasources/supabase_enrollment_data_source.dart';
import '../../features/enrollments/data/repositories/supabase_enrollment_repository.dart';
import '../../features/enrollments/domain/repositories/enrollment_repository.dart';
import '../../features/enrollments/domain/usecases/enrollment_usecases.dart';
import '../../features/enrollments/presentation/bloc/enrollments_bloc.dart';

/// Contenedor compartido por Auth, Plans y Enrollments.
final GetIt locator = GetIt.instance;

void registerAuthDependencies(SupabaseClient client) {
  if (locator.isRegistered<AuthRepository>()) return;
  if (!locator.isRegistered<SupabaseClient>()) {
    locator.registerSingleton<SupabaseClient>(client);
  }
  locator.registerLazySingleton(
    () => SupabaseAuthDataSource(locator<SupabaseClient>()),
  );
  locator.registerLazySingleton<AuthRepository>(
    () => SupabaseAuthRepository(locator<SupabaseAuthDataSource>()),
  );
  locator.registerLazySingleton(
    () => HasSessionUseCase(locator<AuthRepository>()),
  );
  locator.registerLazySingleton(
    () => ObserveSessionUseCase(locator<AuthRepository>()),
  );
  locator.registerLazySingleton(
    () => GetCurrentProfileUseCase(locator<AuthRepository>()),
  );
  locator.registerLazySingleton(
    () => SignOutUseCase(locator<AuthRepository>()),
  );
  locator.registerLazySingleton(() => SignInUseCase(locator<AuthRepository>()));
  locator.registerLazySingleton(() => SignUpUseCase(locator<AuthRepository>()));
  locator.registerLazySingleton(
    () => CheckUsernameAvailabilityUseCase(locator<AuthRepository>()),
  );
  locator.registerFactory(
    () => AuthBloc(
      hasSession: locator<HasSessionUseCase>(),
      observeSession: locator<ObserveSessionUseCase>(),
      getCurrentProfile: locator<GetCurrentProfileUseCase>(),
      signOut: locator<SignOutUseCase>(),
    ),
  );
  locator.registerFactory(() => LoginBloc(signIn: locator<SignInUseCase>()));
  locator.registerFactory(
    () => RegisterBloc(
      signUp: locator<SignUpUseCase>(),
      checkUsername: locator<CheckUsernameAvailabilityUseCase>(),
    ),
  );
}

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

/// Registro independiente para Persona 2. Se integra sin acoplar widgets a SQL.
void registerEnrollmentsDependencies(SupabaseClient client) {
  if (locator.isRegistered<EnrollmentRepository>()) return;
  if (!locator.isRegistered<SupabaseClient>()) {
    locator.registerSingleton<SupabaseClient>(client);
  }
  locator.registerLazySingleton<SupabaseEnrollmentDataSource>(
    () => SupabaseEnrollmentDataSource(locator<SupabaseClient>()),
  );
  locator.registerLazySingleton<EnrollmentRepository>(
    () => SupabaseEnrollmentRepository(locator<SupabaseEnrollmentDataSource>()),
  );
  locator.registerLazySingleton(
    () => EnrollInPlanUseCase(locator<EnrollmentRepository>()),
  );
  locator.registerLazySingleton(
    () => GetMyEnrollmentsUseCase(locator<EnrollmentRepository>()),
  );
  locator.registerLazySingleton(
    () => CancelEnrollmentUseCase(locator<EnrollmentRepository>()),
  );
  locator.registerLazySingleton(
    () => CheckPlanAvailabilityUseCase(locator<EnrollmentRepository>()),
  );
  locator.registerLazySingleton(
    () => GetMyEnrollmentForPlanUseCase(locator<EnrollmentRepository>()),
  );
  locator.registerLazySingleton(
    () => GetPendingRequestsUseCase(locator<EnrollmentRepository>()),
  );
  locator.registerLazySingleton(
    () => ResolveEnrollmentRequestUseCase(locator<EnrollmentRepository>()),
  );
  locator.registerFactory(
    () => EnrollmentsBloc(
      enrollInPlan: locator<EnrollInPlanUseCase>(),
      getMyEnrollments: locator<GetMyEnrollmentsUseCase>(),
      cancelEnrollment: locator<CancelEnrollmentUseCase>(),
      checkPlanAvailability: locator<CheckPlanAvailabilityUseCase>(),
      getMyEnrollmentForPlan: locator<GetMyEnrollmentForPlanUseCase>(),
      getPendingRequests: locator<GetPendingRequestsUseCase>(),
      resolveEnrollmentRequest: locator<ResolveEnrollmentRequestUseCase>(),
    ),
  );
}
