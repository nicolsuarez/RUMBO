import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/emergency_contact.dart';
import '../../domain/usecases/get_emergency_contacts.dart';
import '../../domain/usecases/create_emergency_contact.dart';
import '../../domain/usecases/update_emergency_contact.dart';
import '../../domain/usecases/delete_emergency_contact.dart';

part 'emergency_contact_event.dart';
part 'emergency_contact_state.dart';

class EmergencyContactBloc
    extends Bloc<EmergencyContactEvent, EmergencyContactState> {
  EmergencyContactBloc({
    required this.getEmergencyContacts,
    required this.createEmergencyContact,
    required this.updateEmergencyContact,
    required this.deleteEmergencyContact,
  }) : super(const EmergencyContactState()) {
    on<EmergencyContactsLoadRequested>(_load);
    on<EmergencyContactCreateRequested>(_create);
    on<EmergencyContactUpdateRequested>(_update);
    on<EmergencyContactDeleteRequested>(_delete);
  }

  final GetEmergencyContacts getEmergencyContacts;
  final CreateEmergencyContact createEmergencyContact;
  final UpdateEmergencyContact updateEmergencyContact;
  final DeleteEmergencyContact deleteEmergencyContact;

  Future<void> _load(
    EmergencyContactsLoadRequested event,
    Emitter<EmergencyContactState> emit,
  ) async {
    emit(state.copyWith(loading: true, clearError: true, clearMessage: true));

    try {
      final contacts = await getEmergencyContacts();

      emit(
        state.copyWith(loading: false, contacts: contacts, clearError: true),
      );
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> _create(
    EmergencyContactCreateRequested event,
    Emitter<EmergencyContactState> emit,
  ) async {
    await _act(
      emit,
      () => createEmergencyContact(
        name: event.name,
        phone: event.phone,
        relationship: event.relationship,
      ),
      'Contacto registrado correctamente.',
    );
  }

  Future<void> _update(
    EmergencyContactUpdateRequested event,
    Emitter<EmergencyContactState> emit,
  ) async {
    await _act(
      emit,
      () => updateEmergencyContact(
        id: event.id,
        name: event.name,
        phone: event.phone,
        relationship: event.relationship,
      ),
      'Contacto actualizado correctamente.',
    );
  }

  Future<void> _delete(
    EmergencyContactDeleteRequested event,
    Emitter<EmergencyContactState> emit,
  ) async {
    await _act(
      emit,
      () => deleteEmergencyContact(id: event.id),
      'Contacto eliminado correctamente.',
    );
  }

  Future<void> _act(
    Emitter<EmergencyContactState> emit,
    Future<void> Function() action,
    String successMessage,
  ) async {
    if (state.busy) return;

    emit(state.copyWith(busy: true, clearError: true, clearMessage: true));

    try {
      await action();

      final contacts = await getEmergencyContacts();

      emit(
        state.copyWith(
          busy: false,
          contacts: contacts,
          message: successMessage,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(busy: false, error: e.toString()));
    }
  }
}
