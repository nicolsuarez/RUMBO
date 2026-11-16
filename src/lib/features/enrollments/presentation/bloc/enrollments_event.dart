part of 'enrollments_bloc.dart';

sealed class EnrollmentsEvent {
  const EnrollmentsEvent();
}

class EnrollmentsLoadRequested extends EnrollmentsEvent {
  const EnrollmentsLoadRequested();
}

class EnrollmentsPlanRequested extends EnrollmentsEvent {
  const EnrollmentsPlanRequested(this.planId, {this.includeRequests = false});
  final String planId;
  final bool includeRequests;
}

class EnrollmentsJoinRequested extends EnrollmentsEvent {
  const EnrollmentsJoinRequested(this.planId);
  final String planId;
}

class EnrollmentsCancelRequested extends EnrollmentsEvent {
  const EnrollmentsCancelRequested(this.planId);
  final String planId;
}

class EnrollmentsResolveRequested extends EnrollmentsEvent {
  const EnrollmentsResolveRequested(this.planId, this.enrollmentId,
      {required this.approve});
  final String planId;
  final String enrollmentId;
  final bool approve;
}

class EnrollmentsResetRequested extends EnrollmentsEvent {
  const EnrollmentsResetRequested();
}
