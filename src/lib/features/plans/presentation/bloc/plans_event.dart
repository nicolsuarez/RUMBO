part of 'plans_bloc.dart';

sealed class PlansEvent {
  const PlansEvent();
}

final class PlansLoadRequested extends PlansEvent {
  const PlansLoadRequested({this.organizerId});
  final String? organizerId;
}

final class PlansSaveRequested extends PlansEvent {
  const PlansSaveRequested({
    required this.input,
    required this.publish,
    this.id,
  });
  final PlanInput input;
  final bool publish;
  final String? id;
}

final class PlansCancelRequested extends PlansEvent {
  const PlansCancelRequested(this.id);
  final String id;
}

final class PlansFinishRequested extends PlansEvent {
  const PlansFinishRequested(this.id);
  final String id;
}

final class PlansDeleteDraftRequested extends PlansEvent {
  const PlansDeleteDraftRequested(this.id);
  final String id;
}

final class PlansRefreshRequested extends PlansEvent {
  const PlansRefreshRequested();
}

final class PlansResetRequested extends PlansEvent {
  const PlansResetRequested();
}
