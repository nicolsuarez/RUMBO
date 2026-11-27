import '../repositories/emergency_contact_repository.dart';

class CreateEmergencyContact {
  const CreateEmergencyContact(this.repository);

  final EmergencyContactRepository repository;

  Future<void> call({
    required String name,
    required String phone,
    String? relationship,
  }) {
    return repository.createContact(
      name: name,
      phone: phone,
      relationship: relationship,
    );
  }
}
