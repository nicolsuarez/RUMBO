import '../entities/register_draft.dart';
import '../entities/rumbo_user.dart';
import '../repositories/auth_repository.dart';

class SignUpUseCase {
  const SignUpUseCase(this.repository);
  final AuthRepository repository;
  Future<bool> call(RegisterDraft draft) => repository.signUp(draft);
}

class SignInUseCase {
  const SignInUseCase(this.repository);
  final AuthRepository repository;
  Future<void> call(String email, String password) =>
      repository.signIn(email, password);
}

class GetCurrentProfileUseCase {
  const GetCurrentProfileUseCase(this.repository);
  final AuthRepository repository;
  Future<RumboUser?> call() => repository.currentProfile();
}
