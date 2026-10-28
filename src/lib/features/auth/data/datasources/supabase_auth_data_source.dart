import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/register_draft.dart';
class SupabaseAuthDataSource {
  SupabaseAuthDataSource(this.client);
  final SupabaseClient client;
  Future<AuthResponse> signUp(RegisterDraft draft) => client.auth.signUp(
    email: draft.email.trim(), password: draft.password,
    data: {
      'nombre': draft.name.trim(), 'telefono': draft.phone.trim(),
      'username': draft.username.trim().toLowerCase(),
      'fecha_nacimiento': '${draft.birthDate.year.toString().padLeft(4,'0')}-${draft.birthDate.month.toString().padLeft(2,'0')}-${draft.birthDate.day.toString().padLeft(2,'0')}',
      'intereses': draft.interests,
    },
  );
  Future<void> signIn(String email,String password) async {
    await client.auth.signInWithPassword(email: email.trim(), password: password);
  }
  Future<void> signOut() => client.auth.signOut();
}
