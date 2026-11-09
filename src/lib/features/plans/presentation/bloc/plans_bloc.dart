import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/activity_type.dart';
import '../../domain/entities/plan_entity.dart';
import '../../domain/entities/plan_input.dart';
import '../../domain/entities/plan_image.dart';
import '../../domain/usecases/plan_usecases.dart';

part 'plans_event.dart';
part 'plans_state.dart';

class PlansBloc extends Bloc<PlansEvent, PlansState> {
  PlansBloc({
    required this.getPublishedPlans,
    required this.getOrganizerPlans,
    required this.getActivityTypes,
    required this.createPlan,
    required this.updatePlan,
    required this.cancelPlan,
    required this.finishPlan,
    required this.deleteDraft,
  }) : super(const PlansState()) {
    on<PlansLoadRequested>(_load);
    on<PlansRefreshRequested>((event, emit) async {
      emit(state.copyWith(loading: true, error: null, message: null));
      try {
        await _refresh(emit);
      } catch (e) {
        emit(state.copyWith(loading: false, error: e.toString()));
      }
    });
    on<PlansSaveRequested>(_save);
    on<PlansCancelRequested>(_cancel);
    on<PlansFinishRequested>(_finish);
    on<PlansDeleteDraftRequested>(_deleteDraft);
    on<PlansResetRequested>((event, emit) {
      _organizerId = null;
      emit(const PlansState());
    });
  }

  final GetPublishedPlansUseCase getPublishedPlans;
  final GetOrganizerPlansUseCase getOrganizerPlans;
  final GetActivityTypesUseCase getActivityTypes;
  final CreatePlanUseCase createPlan;
  final UpdatePlanUseCase updatePlan;
  final CancelPlanUseCase cancelPlan;
  final FinishPlanUseCase finishPlan;
  final DeleteDraftUseCase deleteDraft;
  String? _organizerId;

  Future<void> _load(PlansLoadRequested event, Emitter<PlansState> emit) async {
    _organizerId = event.organizerId;
    emit(state.copyWith(loading: true, error: null, message: null));
    try {
      await _refresh(emit);
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> _refresh(Emitter<PlansState> emit, {String? message}) async {
    final publicPlans = await getPublishedPlans();
    final mine = _organizerId == null
        ? <PlanEntity>[]
        : await getOrganizerPlans(_organizerId!);
    final activities = await getActivityTypes();
    emit(
      state.copyWith(
        loading: false,
        saving: false,
        published: publicPlans,
        mine: mine,
        activities: activities,
        error: null,
        message: message,
      ),
    );
  }

  Future<void> _save(PlansSaveRequested event, Emitter<PlansState> emit) async {
    emit(state.copyWith(saving: true, error: null, message: null));
    try {
      if (event.id == null) {
        await createPlan(
          event.input,
          publish: event.publish,
          newImage: event.image,
        );
      } else {
        await updatePlan(
          event.id!,
          event.input,
          publish: event.publish,
          newImage: event.image,
          removeImage: event.removeImage,
        );
      }
      await _refresh(
        emit,
        message: event.publish ? 'Plan publicado' : 'Borrador guardado',
      );
    } catch (e) {
      emit(state.copyWith(saving: false, error: e.toString()));
    }
  }

  Future<void> _cancel(
    PlansCancelRequested event,
    Emitter<PlansState> emit,
  ) async {
    await _action(emit, () async {
      await cancelPlan(event.id);
    }, 'Plan cancelado');
  }

  Future<void> _finish(
    PlansFinishRequested event,
    Emitter<PlansState> emit,
  ) async {
    await _action(emit, () async {
      await finishPlan(event.id);
    }, 'Plan finalizado');
  }

  Future<void> _deleteDraft(
    PlansDeleteDraftRequested event,
    Emitter<PlansState> emit,
  ) async {
    await _action(emit, () => deleteDraft(event.id), 'Borrador eliminado');
  }

  Future<void> _action(
    Emitter<PlansState> emit,
    Future<void> Function() action,
    String message,
  ) async {
    emit(state.copyWith(saving: true, error: null, message: null));
    try {
      await action();
      await _refresh(emit, message: message);
    } catch (e) {
      emit(state.copyWith(saving: false, error: e.toString()));
    }
  }
}
