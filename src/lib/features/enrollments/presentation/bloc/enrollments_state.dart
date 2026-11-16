part of 'enrollments_bloc.dart';

class EnrollmentsState {
  const EnrollmentsState({
    this.loading = false,
    this.mine = const [],
    this.availabilityByPlan = const {},
    this.ownByPlan = const {},
    this.pendingByPlan = const {},
    this.loadingPlanId,
    this.busyPlanId,
    this.error,
    this.message,
  });

  final bool loading;
  final List<EnrollmentEntity> mine;
  final Map<String, PlanAvailability> availabilityByPlan;
  final Map<String, EnrollmentEntity?> ownByPlan;
  final Map<String, List<EnrollmentEntity>> pendingByPlan;
  final String? loadingPlanId;
  final String? busyPlanId;
  final String? error;
  final String? message;

  EnrollmentsState copyWith({
    bool? loading,
    List<EnrollmentEntity>? mine,
    Map<String, PlanAvailability>? availabilityByPlan,
    Map<String, EnrollmentEntity?>? ownByPlan,
    Map<String, List<EnrollmentEntity>>? pendingByPlan,
    String? loadingPlanId,
    bool clearLoadingPlan = false,
    String? busyPlanId,
    bool clearBusyPlan = false,
    String? error,
    bool clearError = false,
    String? message,
    bool clearMessage = false,
  }) => EnrollmentsState(
    loading: loading ?? this.loading,
    mine: mine ?? this.mine,
    availabilityByPlan: availabilityByPlan ?? this.availabilityByPlan,
    ownByPlan: ownByPlan ?? this.ownByPlan,
    pendingByPlan: pendingByPlan ?? this.pendingByPlan,
    loadingPlanId:
        clearLoadingPlan ? null : loadingPlanId ?? this.loadingPlanId,
    busyPlanId: clearBusyPlan ? null : busyPlanId ?? this.busyPlanId,
    error: clearError ? null : error ?? this.error,
    message: clearMessage ? null : message ?? this.message,
  );
}
