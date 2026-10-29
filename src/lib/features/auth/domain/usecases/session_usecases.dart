import '../repositories/auth_repository.dart';

/// Casos de uso para el estado global de autenticación.
class HasSessionUseCase {
  const HasSessionUseCase(this.repository);
  final AuthRepository repository;
  bool call() => repository.hasSession;
}

class ObserveSessionUseCase {
  const ObserveSessionUseCase(this.repository);
  final AuthRepository repository;
  Stream<void> call() => repository.sessionChanges;
}

class SignOutUseCase {
  const SignOutUseCase(this.repository);
  final AuthRepository repository;
  Future<void> call() => repository.signOut();
}
