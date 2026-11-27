part of 'emergency_contact_bloc.dart';

class EmergencyContactState {
  const EmergencyContactState({
    this.contacts = const [],
    this.loading = false,
    this.busy = false,
    this.error,
    this.message,
  });

  final List<EmergencyContact> contacts;
  final bool loading;
  final bool busy;
  final String? error;
  final String? message;

  EmergencyContactState copyWith({
    List<EmergencyContact>? contacts,
    bool? loading,
    bool? busy,
    String? error,
    String? message,
    bool clearError = false,
    bool clearMessage = false,
  }) {
    return EmergencyContactState(
      contacts: contacts ?? this.contacts,
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      error: clearError ? null : error ?? this.error,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}
