import '../../domain/entities/register_draft.dart';
import '../../domain/entities/rumbo_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/supabase_auth_data_source.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this.source);
  final SupabaseAuthDataSource source;
  @override
  bool get hasSession => source.hasSession;
  @override
  Stream<void> get sessionChanges => source.sessionChanges;
  @override
  Future<bool> signUp(RegisterDraft draft) => source.signUp(draft);

  @override
  Future<bool> isUsernameAvailable(String username) =>
      source.isUsernameAvailable(username);

  @override
  Future<void> signIn(String email, String password) =>
      source.signIn(email, password);
  @override
  Future<void> signOut() => source.signOut();
  @override
  Future<RumboUser?> currentProfile() async {
    final userId = source.currentUserId;
    if (userId == null) return null;
    final row = await source.getProfile(userId);
    final relations = await source.getInterestRelations(userId);
    return RumboUser(
      id: row['id_usuario'] as String,
      name: row['nombre'] as String,
      email: row['correo'] as String,
      phone: row['telefono'] as String,
      username: row['username'] as String,
      birthDate: DateTime.parse(row['fecha_nacimiento'] as String),
      role: row['rol'] as String,
      interests: relations
          .map((e) => ((e['interes'] as Map)['nombre']) as String)
          .toList(),
    );
  }
}
