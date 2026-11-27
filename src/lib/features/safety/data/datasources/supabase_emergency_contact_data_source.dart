import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseEmergencyContactDataSource {
  const SupabaseEmergencyContactDataSource(this.client);

  final SupabaseClient client;

  String get currentUserId {
    final userId = client.auth.currentUser?.id;

    if (userId == null) {
      throw StateError('Debes iniciar sesión.');
    }

    return userId;
  }

  static const String columns =
      'id_contacto,id_usuario,nombre,telefono,parentesco';

  Future<List<Map<String, dynamic>>> getContacts() async {
    final response = await client
        .from('contacto_emergencia')
        .select(columns)
        .eq('id_usuario', currentUserId);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createContact({
    required String name,
    required String phone,
    String? relationship,
  }) async {
    final response = await client
        .from('contacto_emergencia')
        .insert({
          'id_usuario': currentUserId,
          'nombre': name.trim(),
          'telefono': phone.trim(),
          'parentesco': relationship?.trim(),
        })
        .select(columns)
        .single();

    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> updateContact({
    required String id,
    required String name,
    required String phone,
    String? relationship,
  }) async {
    final response = await client
        .from('contacto_emergencia')
        .update({
          'nombre': name.trim(),
          'telefono': phone.trim(),
          'parentesco': relationship?.trim(),
        })
        .eq('id_contacto', id)
        .eq('id_usuario', currentUserId)
        .select(columns)
        .maybeSingle();

    if (response == null) {
      throw StateError('No se encontró el contacto o no tienes permiso.');
    }

    return Map<String, dynamic>.from(response);
  }

  Future<void> deleteContact(String id) async {
    await client
        .from('contacto_emergencia')
        .delete()
        .eq('id_contacto', id)
        .eq('id_usuario', currentUserId);
  }
}
