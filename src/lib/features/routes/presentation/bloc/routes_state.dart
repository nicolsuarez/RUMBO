part of 'routes_bloc.dart';

enum RoutesPhase { initial, loading, ready, saving, failure }

class RoutesState {
  const RoutesState({
    this.phase = RoutesPhase.initial,
    this.planId,
    this.route,
    this.error,
  });

  final RoutesPhase phase;
  final String? planId;
  final RouteEntity? route;
  final String? error;

  bool get isBusy =>
      phase == RoutesPhase.loading || phase == RoutesPhase.saving;
  bool get canStart =>
      phase == RoutesPhase.ready && planId != null && route == null;
  bool get canPause =>
      phase == RoutesPhase.ready && route?.status == RouteStatus.active;
  bool get canResume =>
      phase == RoutesPhase.ready && route?.status == RouteStatus.paused;
  bool get canFinish =>
      phase == RoutesPhase.ready && (route?.isInProgress ?? false);
}
