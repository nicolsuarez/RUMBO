part of 'auth_bloc.dart';

sealed class AuthEvent {
  const AuthEvent();
}

/// Se dispara al crear el Bloc para restaurar la sesión existente.
final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

/// Señal emitida cuando Supabase informa un cambio de autenticación.
final class AuthSessionChanged extends AuthEvent {
  const AuthSessionChanged();
}

final class AuthRetryRequested extends AuthEvent {
  const AuthRetryRequested();
}

final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}
