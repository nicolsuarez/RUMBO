import '../entities/emergency_contact.dart';

abstract class EmergencyContactRepository {
  Future<List<EmergencyContact>> getContacts();

  Future<void> createContact({
    required String name,
    required String phone,
    String? relationship,
  });

  Future<void> updateContact({
    required String id,
    required String name,
    required String phone,
    String? relationship,
  });

  Future<void> deleteContact({required String id});
}
