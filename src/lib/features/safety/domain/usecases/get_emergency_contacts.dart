import '../entities/emergency_contact.dart';
import '../repositories/emergency_contact_repository.dart';

class GetEmergencyContacts {
  const GetEmergencyContacts(this.repository);

  final EmergencyContactRepository repository;

  Future<List<EmergencyContact>> call() {
    return repository.getContacts();
  }
}
