import '../../domain/entities/emergency_contact.dart';
import '../../domain/repositories/emergency_contact_repository.dart';
import '../datasources/supabase_emergency_contact_data_source.dart';
import '../models/emergency_contact_model.dart';

class EmergencyContactRepositoryImpl implements EmergencyContactRepository {
  const EmergencyContactRepositoryImpl(this.dataSource);

  final SupabaseEmergencyContactDataSource dataSource;

  @override
  Future<List<EmergencyContact>> getContacts() async {
    final rows = await dataSource.getContacts();

    return rows.map((json) => EmergencyContactModel.fromJson(json)).toList();
  }

  @override
  Future<void> createContact({
    required String name,
    required String phone,
    String? relationship,
  }) async {
    await dataSource.createContact(
      name: name,
      phone: phone,
      relationship: relationship,
    );
  }

  @override
  Future<void> updateContact({
    required String id,
    required String name,
    required String phone,
    String? relationship,
  }) async {
    await dataSource.updateContact(
      id: id,
      name: name,
      phone: phone,
      relationship: relationship,
    );
  }

  @override
  Future<void> deleteContact({required String id}) async {
    await dataSource.deleteContact(id);
  }
}
