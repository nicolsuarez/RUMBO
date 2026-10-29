part of 'register_bloc.dart';

sealed class RegisterEvent {
  const RegisterEvent();
}

final class RegisterSubmitted extends RegisterEvent {
  const RegisterSubmitted(this.draft);

  final RegisterDraft draft;
}

final class RegisterUsernameCheckRequested extends RegisterEvent {
  const RegisterUsernameCheckRequested(this.username);

  final String username;
}
