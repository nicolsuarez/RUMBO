import '../repositories/emergency_contact_repository.dart';

class UpdateEmergencyContact {
  const UpdateEmergencyContact(this.repository);

  final EmergencyContactRepository repository;

  Future<void> call({
    required String id,
    required String name,
    required String phone,
    String? relationship,
  }) {
    return repository.updateContact(
      id: id,
      name: name,
      phone: phone,
      relationship: relationship,
    );
  }
}
