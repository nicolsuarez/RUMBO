part of 'routes_bloc.dart';

abstract class RoutesEvent {
  const RoutesEvent();
}

class RoutesLoadRequested extends RoutesEvent {
  const RoutesLoadRequested(
    this.planId, {
    this.allowAutomaticProgress = true,
    this.totalDistanceKm,
  });
  final String planId;
  final bool allowAutomaticProgress;
  final double? totalDistanceKm;
}

class RoutesStartRequested extends RoutesEvent {
  const RoutesStartRequested();
}

class RoutesPauseRequested extends RoutesEvent {
  const RoutesPauseRequested();
}

class RoutesResumeRequested extends RoutesEvent {
  const RoutesResumeRequested();
}

class RoutesFinishRequested extends RoutesEvent {
  const RoutesFinishRequested();
}

class _RoutesTick extends RoutesEvent {
  const _RoutesTick(this.generation);
  final int generation;
}
