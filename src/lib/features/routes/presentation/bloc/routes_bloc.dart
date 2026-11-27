import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/route_entity.dart';
import '../../domain/entities/route_simulation_rate.dart';
import '../../domain/usecases/route_usecases.dart';

part 'routes_event.dart';
part 'routes_state.dart';

/// BLoC de un plan. La única fuente de progreso es la respuesta persistida.
/// La UI debe cerrar este BLoC al salir de la pantalla o cerrar sesión.
class RoutesBloc extends Bloc<RoutesEvent, RoutesState> {
  RoutesBloc({
    required this.getMyRouteForPlan,
    required this.startRoute,
    required this.updateRouteProgress,
    required this.pauseRoute,
    required this.resumeRoute,
    required this.finishRoute,
    this.tickInterval = const Duration(seconds: 5),
    this.progressStep = 2.0,
  }) : super(const RoutesState()) {
    if (tickInterval <= Duration.zero) {
      throw ArgumentError.value(tickInterval, 'tickInterval');
    }
    if (!progressStep.isFinite || progressStep <= 0 || progressStep > 100) {
      throw ArgumentError.value(progressStep, 'progressStep');
    }
    // Un único registro de eventos: asyncExpand serializa incluso eventos
    // de tipos diferentes, sin agregar bloc_concurrency como dependencia.
    on<RoutesEvent>(
      _handle,
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
  }

  final GetMyRouteForPlanUseCase getMyRouteForPlan;
  final StartRouteUseCase startRoute;
  final UpdateRouteProgressUseCase updateRouteProgress;
  final PauseRouteUseCase pauseRoute;
  final ResumeRouteUseCase resumeRoute;
  final FinishRouteUseCase finishRoute;
  final Duration tickInterval;
  final double progressStep;

  Timer? _timer;
  int _generation = 0;
  bool _closing = false;
  bool _allowAutomaticProgress = true;
  double? _totalDistanceKm;

  double get effectiveProgressStep =>
      RouteSimulationRate.hasDistance(_totalDistanceKm)
      ? RouteSimulationRate.progressStepFor(_totalDistanceKm!)
      : progressStep;

  Future<void> _handle(RoutesEvent event, Emitter<RoutesState> emit) async {
    if (_closing) return;
    if (event is RoutesLoadRequested) {
      _totalDistanceKm = event.totalDistanceKm;
      _allowAutomaticProgress =
          event.allowAutomaticProgress &&
          (event.totalDistanceKm == null ||
              RouteSimulationRate.hasDistance(event.totalDistanceKm));
      await _load(event.planId, emit);
      return;
    }
    final planId = state.planId;
    final route = state.route;
    if (planId == null || state.phase != RoutesPhase.ready) return;

    if (event is RoutesStartRequested &&
        state.canStart &&
        _allowAutomaticProgress) {
      await _save(emit, () => startRoute(planId));
    } else if (event is RoutesPauseRequested && state.canPause) {
      await _save(emit, () => pauseRoute(route!.id));
    } else if (event is RoutesResumeRequested &&
        state.canResume &&
        _allowAutomaticProgress) {
      await _save(emit, () => resumeRoute(route!.id));
    } else if (event is RoutesFinishRequested && state.canFinish) {
      await _save(emit, () => finishRoute(route!.id));
    } else if (event is _RoutesTick &&
        event.generation == _generation &&
        _allowAutomaticProgress &&
        route != null &&
        route.status == RouteStatus.active &&
        route.progress < 100) {
      final current = route;
      final target = math.min(100.0, current.progress + effectiveProgressStep);
      await _save(emit, () => updateRouteProgress(current.id, target));
    }
  }

  Future<void> _load(String planId, Emitter<RoutesState> emit) async {
    _stopTimer();
    final previous = state.planId == planId ? state.route : null;
    emit(
      RoutesState(phase: RoutesPhase.loading, planId: planId, route: previous),
    );
    try {
      final route = await getMyRouteForPlan(planId);
      if (_closing || emit.isDone) return;
      emit(RoutesState(phase: RoutesPhase.ready, planId: planId, route: route));
      _scheduleTick();
    } catch (error) {
      if (_closing || emit.isDone) return;
      emit(
        RoutesState(
          phase: RoutesPhase.failure,
          planId: planId,
          route: previous,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> _save(
    Emitter<RoutesState> emit,
    Future<RouteEntity> Function() operation,
  ) async {
    _stopTimer();
    final previous = state;
    emit(
      RoutesState(
        phase: RoutesPhase.saving,
        planId: previous.planId,
        route: previous.route,
      ),
    );
    try {
      final route = await operation();
      if (_closing || emit.isDone) return;
      emit(
        RoutesState(
          phase: RoutesPhase.ready,
          planId: previous.planId,
          route: route,
        ),
      );
      _scheduleTick();
    } catch (error) {
      if (_closing || emit.isDone) return;
      // Una respuesta perdida no implica que el servidor no haya escrito.
      // Exigir recarga antes de otra acción; jamás inventar un nuevo estado.
      emit(
        RoutesState(
          phase: RoutesPhase.failure,
          planId: previous.planId,
          route: previous.route,
          error: error.toString(),
        ),
      );
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _generation++;
  }

  void _scheduleTick() {
    _stopTimer();
    final route = state.route;

    if (_closing ||
        isClosed ||
        state.phase != RoutesPhase.ready ||
        route == null) {
      return;
    }

    // Finalización automática al completar el recorrido.
    if (state.canFinish && route.progress >= 100) {
      add(const RoutesFinishRequested());
      return;
    }

    if (!_allowAutomaticProgress || route.status != RouteStatus.active) {
      return;
    }

    final generation = _generation;

    _timer = Timer(tickInterval, () {
      _timer = null;
      if (!_closing && !isClosed && generation == _generation) {
        add(_RoutesTick(generation));
      }
    });
  }

  @override
  Future<void> close() {
    _closing = true;
    _stopTimer();
    return super.close();
  }
}
