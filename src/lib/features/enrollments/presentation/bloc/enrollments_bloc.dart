import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/enrollment_entity.dart';
import '../../domain/usecases/enrollment_usecases.dart';

part 'enrollments_event.dart';
part 'enrollments_state.dart';

/// BLoC compartido entre detalle, Mis planes y solicitudes del organizador.
class EnrollmentsBloc extends Bloc<EnrollmentsEvent, EnrollmentsState> {
  EnrollmentsBloc({
    required this.enrollInPlan,
    required this.getMyEnrollments,
    required this.cancelEnrollment,
    required this.checkPlanAvailability,
    required this.getMyEnrollmentForPlan,
    required this.getPendingRequests,
    required this.resolveEnrollmentRequest,
  }) : super(const EnrollmentsState()) {
    on<EnrollmentsLoadRequested>((event, emit) => _load(emit));
    on<EnrollmentsPlanRequested>(_plan);
    on<EnrollmentsJoinRequested>((event, emit) => _act(
          event.planId,
          emit,
          () => enrollInPlan(event.planId),
          'Inscripción registrada. Revisa su estado en Mis planes.',
        ));
    on<EnrollmentsCancelRequested>((event, emit) => _act(
          event.planId,
          emit,
          () => cancelEnrollment(event.planId),
          'Inscripción cancelada.',
        ));
    on<EnrollmentsResolveRequested>((event, emit) => _act(
          event.planId,
          emit,
          () => resolveEnrollmentRequest(event.enrollmentId,
              approve: event.approve),
          event.approve ? 'Solicitud aprobada.' : 'Solicitud rechazada.',
        ));
    on<EnrollmentsResetRequested>((event, emit) {
      _focusedPlanId = null;
      _includeRequests = false;
      emit(const EnrollmentsState());
    });
  }

  final EnrollInPlanUseCase enrollInPlan;
  final GetMyEnrollmentsUseCase getMyEnrollments;
  final CancelEnrollmentUseCase cancelEnrollment;
  final CheckPlanAvailabilityUseCase checkPlanAvailability;
  final GetMyEnrollmentForPlanUseCase getMyEnrollmentForPlan;
  final GetPendingRequestsUseCase getPendingRequests;
  final ResolveEnrollmentRequestUseCase resolveEnrollmentRequest;

  String? _focusedPlanId;
  bool _includeRequests = false;

  Future<void> _load(Emitter<EnrollmentsState> emit) async {
    emit(state.copyWith(loading: true, clearError: true, clearMessage: true));
    try {
      final items = await getMyEnrollments();
      emit(state.copyWith(loading: false, mine: items, clearError: true));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> _plan(EnrollmentsPlanRequested event,
      Emitter<EnrollmentsState> emit) async {
    _focusedPlanId = event.planId;
    _includeRequests = event.includeRequests;
    emit(state.copyWith(loadingPlanId: event.planId, clearError: true));
    try {
      await _refreshPlan(event.planId, emit,
          includeRequests: event.includeRequests);
    } catch (e) {
      emit(state.copyWith(clearLoadingPlan: true, error: e.toString()));
    }
  }

  Future<void> _refreshPlan(String planId, Emitter<EnrollmentsState> emit,
      {required bool includeRequests}) async {
    final availability = await checkPlanAvailability(planId);
    final own = await getMyEnrollmentForPlan(planId);
    final requests = includeRequests
        ? await getPendingRequests(planId)
        : state.pendingByPlan[planId] ?? <EnrollmentEntity>[];
    emit(state.copyWith(
      clearLoadingPlan: true,
      availabilityByPlan: {...state.availabilityByPlan, planId: availability},
      ownByPlan: {...state.ownByPlan, planId: own},
      pendingByPlan: {...state.pendingByPlan, planId: requests},
      clearError: true,
    ));
  }

  Future<void> _act(String planId, Emitter<EnrollmentsState> emit,
      Future<void> Function() action, String message) async {
    if (state.busyPlanId != null) return;
    emit(state.copyWith(
      busyPlanId: planId,
      clearError: true,
      clearMessage: true,
    ));
    try {
      await action();
      final mine = await getMyEnrollments();
      emit(state.copyWith(mine: mine, clearError: true));
      await _refreshPlan(planId, emit,
          includeRequests: _focusedPlanId == planId && _includeRequests);
      emit(state.copyWith(clearBusyPlan: true, message: message));
    } catch (e) {
      emit(state.copyWith(
        clearBusyPlan: true,
        clearLoadingPlan: true,
        error: e.toString(),
      ));
    }
  }
}
