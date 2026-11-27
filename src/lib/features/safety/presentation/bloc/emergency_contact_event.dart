part of 'emergency_contact_bloc.dart';

abstract class EmergencyContactEvent {
  const EmergencyContactEvent();
}

class EmergencyContactsLoadRequested extends EmergencyContactEvent {
  const EmergencyContactsLoadRequested();
}

class EmergencyContactCreateRequested extends EmergencyContactEvent {
  const EmergencyContactCreateRequested({
    required this.name,
    required this.phone,
    this.relationship,
  });

  final String name;
  final String phone;
  final String? relationship;
}

class EmergencyContactUpdateRequested extends EmergencyContactEvent {
  const EmergencyContactUpdateRequested({
    required this.id,
    required this.name,
    required this.phone,
    this.relationship,
  });

  final String id;
  final String name;
  final String phone;
  final String? relationship;
}

class EmergencyContactDeleteRequested extends EmergencyContactEvent {
  const EmergencyContactDeleteRequested(this.id);

  final String id;
}
