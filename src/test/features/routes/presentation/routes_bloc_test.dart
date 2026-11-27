import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rumbo/features/routes/domain/entities/route_entity.dart';
import 'package:rumbo/features/routes/domain/repositories/route_repository.dart';
import 'package:rumbo/features/routes/domain/usecases/route_usecases.dart';
import 'package:rumbo/features/routes/presentation/bloc/routes_bloc.dart';

RouteEntity _route(
  RouteStatus status,
  double progress, {
  String planId = 'plan',
}) => RouteEntity(
  id: 'route',
  enrollmentId: 'enrollment',
  userId: 'user',
  planId: planId,
  startedAt: DateTime.utc(2026, 11, 26),
  finishedAt: status == RouteStatus.finished
      ? DateTime.utc(2026, 11, 26, 1)
      : null,
  status: status,
  progress: progress,
  distanceKm: progress / 10,
);

class _FakeRepository implements RouteRepository {
  RouteEntity? persisted;
  Object? failure;
  Completer<void>? advanceGate;
  final List<String> calls = [];
  double? lastTarget;

  void _check(String operation) {
    calls.add(operation);
    final error = failure;
    if (error != null) throw error;
  }

  @override
  Future<RouteEntity?> myRouteForPlan(String planId) async {
    _check('load');
    return persisted?.planId == planId ? persisted : null;
  }

  @override
  Future<RouteEntity?> myActiveRoute() async =>
      persisted?.isInProgress == true ? persisted : null;

  @override
  Future<RouteEntity> start(String planId) async {
    _check('start');
    return persisted = _route(RouteStatus.active, 0, planId: planId);
  }

  @override
  Future<RouteEntity> updateProgress(String routeId, double progress) async {
    _check('advance');
    lastTarget = progress;
    final gate = advanceGate;
    if (gate != null) await gate.future;
    return persisted = _route(RouteStatus.active, progress);
  }

  @override
  Future<RouteEntity> pause(String routeId) async {
    _check('pause');
    return persisted = _route(RouteStatus.paused, persisted!.progress);
  }

  @override
  Future<RouteEntity> resume(String routeId) async {
    _check('resume');
    return persisted = _route(RouteStatus.active, persisted!.progress);
  }

  @override
  Future<RouteEntity> finish(String routeId) async {
    _check('finish');
    return persisted = _route(RouteStatus.finished, persisted!.progress);
  }
}

const _interval = Duration(milliseconds: 250);
const _noTickWindow = Duration(milliseconds: 600);
const _operationTimeout = Duration(seconds: 3);

RoutesBloc _bloc(_FakeRepository repository) => RoutesBloc(
  tickInterval: _interval,
  getMyRouteForPlan: GetMyRouteForPlanUseCase(repository),
  startRoute: StartRouteUseCase(repository),
  updateRouteProgress: UpdateRouteProgressUseCase(repository),
  pauseRoute: PauseRouteUseCase(repository),
  resumeRoute: ResumeRouteUseCase(repository),
  finishRoute: FinishRouteUseCase(repository),
);

// Tests unitarios: se utiliza el reloj real, sin el entorno FakeAsync
// de testWidgets. Cada espera de estado tiene un límite explícito.
Future<RoutesState> _waitFor(
  RoutesBloc bloc,
  bool Function(RoutesState) predicate,
) {
  if (predicate(bloc.state)) return Future.value(bloc.state);
  return bloc.stream.firstWhere(predicate).timeout(_operationTimeout);
}

Future<void> _load(RoutesBloc bloc) async {
  bloc.add(const RoutesLoadRequested('plan'));
  await _waitFor(bloc, (s) => s.phase == RoutesPhase.ready);
}

Future<void> _close(RoutesBloc bloc) => bloc.close().timeout(_operationTimeout);

void main() {
  late _FakeRepository repo;
  setUp(() => repo = _FakeRepository());

  test('carga vacía y crea un recorrido solo una vez', () async {
    final bloc = _bloc(repo);
    try {
      await _load(bloc);
      expect(bloc.state.canStart, isTrue);
      bloc.add(const RoutesStartRequested());
      bloc.add(const RoutesStartRequested());
      await _waitFor(bloc, (s) => s.canPause);
      await Future<void>.delayed(Duration.zero);
      expect(repo.calls, ['load', 'start']);
      expect(bloc.state.route?.progress, 0);
      expect(bloc.state.canPause, isTrue);
    } finally {
      await _close(bloc);
    }
  });

  test('recupera un recorrido pausado sin reiniciar avance', () async {
    repo.persisted = _route(RouteStatus.paused, 37.5);
    final bloc = _bloc(repo);
    try {
      await _load(bloc);
      await Future<void>.delayed(_noTickWindow);
      expect(bloc.state.route?.progress, 37.5);
      expect(bloc.state.canResume, isTrue);
      expect(repo.calls, ['load']);
    } finally {
      await _close(bloc);
    }
  });

  test('avance conserva la respuesta confirmada por el repositorio', () async {
    repo.persisted = _route(RouteStatus.active, 37.5);
    final bloc = _bloc(repo);
    try {
      await _load(bloc);
      final state = await _waitFor(
        bloc,
        (s) => s.phase == RoutesPhase.ready && s.route?.progress == 39.5,
      );
      expect(repo.lastTarget, 39.5);
      expect(state.route, same(repo.persisted));
      expect(state.route?.progress, 39.5);
    } finally {
      await _close(bloc);
    }
  });

  test('pausa detiene avance y reanudar conserva progreso', () async {
    repo.persisted = _route(RouteStatus.active, 24);
    final bloc = _bloc(repo);
    try {
      await _load(bloc);
      bloc.add(const RoutesPauseRequested());
      await _waitFor(bloc, (s) => s.canResume);
      await Future<void>.delayed(_noTickWindow);
      expect(bloc.state.route?.progress, 24);
      expect(repo.calls, ['load', 'pause']);
      bloc.add(const RoutesResumeRequested());
      final resumed = await _waitFor(bloc, (s) => s.canPause);
      expect(resumed.route?.progress, 24);
      await _waitFor(
        bloc,
        (s) => s.phase == RoutesPhase.ready && s.route?.progress == 26,
      );
      expect(repo.calls, ['load', 'pause', 'resume', 'advance']);
    } finally {
      await _close(bloc);
    }
  });

  test('finalizar desde pausa conserva avance y no permite reanudar', () async {
    repo.persisted = _route(RouteStatus.paused, 62);
    final bloc = _bloc(repo);
    try {
      await _load(bloc);
      bloc.add(const RoutesFinishRequested());
      await _waitFor(
        bloc,
        (s) =>
            s.phase == RoutesPhase.ready &&
            s.route?.status == RouteStatus.finished,
      );
      bloc.add(const RoutesResumeRequested());
      bloc.add(const RoutesStartRequested());
      await Future<void>.delayed(_noTickWindow);
      expect(bloc.state.route?.status, RouteStatus.finished);
      expect(bloc.state.route?.progress, 62);
      expect(bloc.state.route?.finishedAt, isNotNull);
      expect(repo.calls, ['load', 'finish']);
    } finally {
      await _close(bloc);
    }
  });

  test('finaliza automáticamente al alcanzar el 100 %', () async {
    repo.persisted = _route(RouteStatus.active, 99.5);
    final bloc = _bloc(repo);

    try {
      await _load(bloc);

      await _waitFor(
        bloc,
        (s) =>
            s.phase == RoutesPhase.ready &&
            s.route?.status == RouteStatus.finished,
      );

      await Future<void>.delayed(_noTickWindow);

      expect(repo.lastTarget, 100);
      expect(bloc.state.route?.status, RouteStatus.finished);
      expect(bloc.state.route?.progress, 100);
      expect(bloc.state.route?.finishedAt, isNotNull);
      expect(bloc.state.canFinish, isFalse);
      expect(repo.calls, ['load', 'advance', 'finish']);
    } finally {
      await _close(bloc);
    }
  });

  test('error de inicio no inventa recorrido y exige recarga', () async {
    final bloc = _bloc(repo);
    try {
      await _load(bloc);
      repo.failure = StateError('Necesitas una inscripción confirmada');
      bloc.add(const RoutesStartRequested());
      await _waitFor(bloc, (s) => s.phase == RoutesPhase.failure);
      expect(bloc.state.route, isNull);
      expect(bloc.state.error, contains('inscripción confirmada'));
      expect(bloc.state.canStart, isFalse);
      repo.failure = null;
      bloc.add(const RoutesLoadRequested('plan'));
      await _waitFor(bloc, (s) => s.canStart);
      expect(bloc.state.canStart, isTrue);
    } finally {
      await _close(bloc);
    }
  });

  test(
    'error de avance detiene el temporizador y permite recuperar y finalizar',
    () async {
      repo.persisted = _route(RouteStatus.active, 40);
      final bloc = _bloc(repo);
      try {
        await _load(bloc);
        repo.failure = StateError('No puedes continuar');
        await _waitFor(bloc, (s) => s.phase == RoutesPhase.failure);
        expect(bloc.state.route?.progress, 40);
        await Future<void>.delayed(_noTickWindow);
        expect(repo.calls, ['load', 'advance']);
        repo.failure = null;
        await _load(bloc);
        bloc.add(const RoutesFinishRequested());
        await _waitFor(
          bloc,
          (s) =>
              s.phase == RoutesPhase.ready &&
              s.route?.status == RouteStatus.finished,
        );
        expect(bloc.state.route?.progress, 40);
      } finally {
        await _close(bloc);
      }
    },
  );

  test(
    'serializa pausa detrás de avance pendiente sin duplicar ticks',
    () async {
      repo.persisted = _route(RouteStatus.active, 10);
      final gate = Completer<void>();
      repo.advanceGate = gate;
      final bloc = _bloc(repo);
      try {
        await _load(bloc);
        await _waitFor(bloc, (s) => s.phase == RoutesPhase.saving);
        expect(repo.calls, ['load', 'advance']);
        expect(bloc.state.isBusy, isTrue);
        bloc.add(const RoutesPauseRequested());
        await Future<void>.delayed(_noTickWindow);
        expect(repo.calls, ['load', 'advance']);
        gate.complete();
        await _waitFor(bloc, (s) => s.canResume);
        expect(repo.calls, ['load', 'advance', 'pause']);
        expect(bloc.state.route?.status, RouteStatus.paused);
        expect(bloc.state.route?.progress, 12);
        await Future<void>.delayed(_noTickWindow);
        expect(repo.calls, ['load', 'advance', 'pause']);
      } finally {
        if (!gate.isCompleted) gate.complete();
        await _close(bloc);
      }
    },
  );

  test('cerrar cancela el temporizador', () async {
    repo.persisted = _route(RouteStatus.active, 12);
    final bloc = _bloc(repo);
    try {
      await _load(bloc);
    } finally {
      await _close(bloc);
    }
    await Future<void>.delayed(_noTickWindow);
    expect(repo.calls, ['load']);
  });
}
