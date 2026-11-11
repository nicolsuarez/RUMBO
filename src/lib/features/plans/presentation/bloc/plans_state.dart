part of 'plans_bloc.dart';

class PlansState {
  const PlansState({
    this.loading = false,
    this.saving = false,
    this.published = const [],
    this.mine = const [],
    this.activities = const [],
    this.error,
    this.message,
  });

  final bool loading;
  final bool saving;
  final List<PlanEntity> published;
  final List<PlanEntity> mine;
  final List<ActivityType> activities;
  final String? error;
  final String? message;

  PlansState copyWith({
    bool? loading,
    bool? saving,
    List<PlanEntity>? published,
    List<PlanEntity>? mine,
    List<ActivityType>? activities,
    String? error,
    String? message,
  }) => PlansState(
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    published: published ?? this.published,
    mine: mine ?? this.mine,
    activities: activities ?? this.activities,
    error: error,
    message: message,
  );
}
