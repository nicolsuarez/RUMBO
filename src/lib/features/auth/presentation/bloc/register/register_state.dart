part of 'register_bloc.dart';

sealed class RegisterState {
  const RegisterState();
}

final class RegisterInitial extends RegisterState {
  const RegisterInitial();
}

final class RegisterSubmitting extends RegisterState {
  const RegisterSubmitting();
}

final class RegisterSuccess extends RegisterState {
  const RegisterSuccess({required this.requiresEmailConfirmation});

  final bool requiresEmailConfirmation;
}

final class RegisterFailure extends RegisterState {
  const RegisterFailure(this.message);

  final String message;
}

// Estados para la comprobación del username.

final class RegisterUsernameChecking extends RegisterState {
  const RegisterUsernameChecking(this.username);

  final String username;
}

final class RegisterUsernameAvailable extends RegisterState {
  const RegisterUsernameAvailable(this.username);

  final String username;
}

final class RegisterUsernameTaken extends RegisterState {
  const RegisterUsernameTaken(this.username);

  final String username;
}

final class RegisterUsernameCheckFailure extends RegisterState {
  const RegisterUsernameCheckFailure(this.message);

  final String message;
}
