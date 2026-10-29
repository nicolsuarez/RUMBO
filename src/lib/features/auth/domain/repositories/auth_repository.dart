import '../entities/register_draft.dart';
import '../entities/rumbo_user.dart';

abstract class AuthRepository {
  Future<bool> signUp(RegisterDraft draft);

  Future<void> signIn(String email, String password);

  Future<void> signOut();

  Future<RumboUser?> currentProfile();

  // Nueva operación de dominio.
  Future<bool> isUsernameAvailable(String username);

  bool get hasSession;

  Stream<void> get sessionChanges;
}
