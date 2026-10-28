import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/register_draft.dart';
import '../../domain/entities/rumbo_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/supabase_auth_data_source.dart';
class SupabaseAuthRepository implements AuthRepository {
 SupabaseAuthRepository(this.source);
 final SupabaseAuthDataSource source;
 SupabaseClient get _db => source.client;
 @override bool get hasSession => _db.auth.currentSession != null;
 @override Stream<void> get sessionChanges => _db.auth.onAuthStateChange.map((_) {});
 @override Future<bool> signUp(RegisterDraft draft) async {
   final result = await source.signUp(draft);
   if (result.user == null) throw StateError('No se pudo crear la cuenta');
   return result.session == null;
 }
 @override Future<void> signIn(String email,String password) => source.signIn(email,password);
 @override Future<void> signOut() => source.signOut();
 @override Future<RumboUser?> currentProfile() async {
   final sessionUser = _db.auth.currentUser;
   if (sessionUser == null) return null;
   final row = await _db.from('usuario').select('id_usuario,nombre,correo,telefono,username,fecha_nacimiento,rol').eq('id_usuario',sessionUser.id).single();
   final relations = await _db.from('usuario_interes').select('interes(nombre)').eq('id_usuario',sessionUser.id);
   return RumboUser(
     id: row['id_usuario'] as String, name: row['nombre'] as String,
     email: row['correo'] as String, phone: row['telefono'] as String,
     username: row['username'] as String, birthDate: DateTime.parse(row['fecha_nacimiento'] as String),
     role: row['rol'] as String,
     interests: (relations as List).map((e) => ((e['interes'] as Map)['nombre']) as String).toList(),
   );
 }
}
