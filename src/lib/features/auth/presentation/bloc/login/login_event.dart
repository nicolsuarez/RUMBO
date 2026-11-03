part of 'login_bloc.dart';

sealed class LoginEvent {
  const LoginEvent();
}

final class LoginSubmitted extends LoginEvent {
  const LoginSubmitted({required this.email, required this.password});
  final String email;
  final String password;
}
