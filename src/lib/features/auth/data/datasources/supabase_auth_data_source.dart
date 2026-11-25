import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/register_draft.dart';

class SupabaseAuthDataSource {
  SupabaseAuthDataSource(this._client);
  final SupabaseClient _client;

  bool get hasSession => _client.auth.currentSession != null;
  Stream<void> get sessionChanges => _client.auth.onAuthStateChange.map((_) {});
  String? get currentUserId => _client.auth.currentUser?.id;

  Future<bool> signUp(RegisterDraft draft) async {
    final result = await _client.auth.signUp(
      email: draft.email.trim(),
      password: draft.password,
      data: {
        'nombre': draft.name.trim(),
        'telefono': draft.phone.trim(),
        'username': draft.username.trim().toLowerCase(),
        'fecha_nacimiento':
            '${draft.birthDate.year.toString().padLeft(4, '0')}-${draft.birthDate.month.toString().padLeft(2, '0')}-${draft.birthDate.day.toString().padLeft(2, '0')}',
        'intereses': draft.interests,
      },
    );
    if (result.user == null) throw StateError('No se pudo crear la cuenta');
    return result.session == null;
  }

  Future<bool> isUsernameAvailable(String username) async {
    final result = await _client.rpc(
      'is_username_available',
      params: {'requested_username': username.trim().toLowerCase()},
    );
    if (result is! bool) {
      throw StateError('No se pudo comprobar la disponibilidad del usuario.');
    }
    return result;
  }

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<Map<String, dynamic>> getProfile(String userId) => _client
      .from('usuario')
      .select('id_usuario,nombre,correo,telefono,username,fecha_nacimiento,rol')
      .eq('id_usuario', userId)
      .single();

  Future<List<Map<String, dynamic>>> getInterestRelations(String userId) =>
      _client
          .from('usuario_interes')
          .select('interes(nombre)')
          .eq('id_usuario', userId);
}
