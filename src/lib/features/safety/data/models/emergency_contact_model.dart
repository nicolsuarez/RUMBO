import '../../domain/entities/emergency_contact.dart';

class EmergencyContactModel {
  const EmergencyContactModel._();

  static EmergencyContact fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id_contacto'] as String,
      userId: json['id_usuario'] as String,
      name: json['nombre'] as String,
      phone: json['telefono'] as String,
      relationship: json['parentesco'] as String?,
    );
  }
}
