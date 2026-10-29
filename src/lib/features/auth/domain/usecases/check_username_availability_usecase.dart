import '../repositories/auth_repository.dart';

class CheckUsernameAvailabilityUseCase {
  const CheckUsernameAvailabilityUseCase(this.repository);

  final AuthRepository repository;

  Future<bool> call(String username) {
    final normalized = username.trim().toLowerCase();

    return repository.isUsernameAvailable(normalized);
  }
}
