import '../repositories/emergency_contact_repository.dart';

class DeleteEmergencyContact {
  const DeleteEmergencyContact(this.repository);

  final EmergencyContactRepository repository;

  Future<void> call({required String id}) {
    return repository.deleteContact(id: id);
  }
}
