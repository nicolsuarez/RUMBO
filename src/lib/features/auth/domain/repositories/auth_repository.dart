import '../entities/register_draft.dart';
import '../entities/rumbo_user.dart';
abstract class AuthRepository {
  Future<bool> signUp(RegisterDraft draft); // true => confirmar correo
  Future<void> signIn(String email, String password);
  Future<void> signOut();
  Future<RumboUser?> currentProfile();
  bool get hasSession;
  Stream<void> get sessionChanges;
}
