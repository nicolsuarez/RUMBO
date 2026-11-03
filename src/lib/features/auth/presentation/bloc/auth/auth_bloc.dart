import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/rumbo_user.dart';
import '../../../domain/usecases/auth_usecases.dart';
import '../../../domain/usecases/session_usecases.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Estado global de sesión. Los tokens se persisten en supabase_flutter,
/// no en este Bloc. No depende de clases concretas de Supabase.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required HasSessionUseCase hasSession,
    required ObserveSessionUseCase observeSession,
    required GetCurrentProfileUseCase getCurrentProfile,
    required SignOutUseCase signOut,
  }) : _hasSession = hasSession,
       _observeSession = observeSession,
       _getCurrentProfile = getCurrentProfile,
       _signOut = signOut,
       super(const AuthInitial()) {
    on<AuthStarted>(_refresh);
    on<AuthSessionChanged>(_refresh);
    on<AuthRetryRequested>(_refresh);
    on<AuthSignOutRequested>(_signOutRequested);

    _subscription = _observeSession().listen(
      (_) => add(const AuthSessionChanged()),
      onError: (Object error, StackTrace stackTrace) {
        add(const AuthRetryRequested());
      },
    );
    add(const AuthStarted());
  }

  final HasSessionUseCase _hasSession;
  final ObserveSessionUseCase _observeSession;
  final GetCurrentProfileUseCase _getCurrentProfile;
  final SignOutUseCase _signOut;
  late final StreamSubscription<void> _subscription;
  int _requestVersion = 0;

  Future<void> _refresh(AuthEvent event, Emitter<AuthState> emit) async {
    final version = ++_requestVersion;
    if (!_hasSession()) {
      emit(const AuthUnauthenticated());
      return;
    }
    if (state is! AuthAuthenticated) emit(const AuthLoading());
    try {
      final user = await _getCurrentProfile();
      if (isClosed || version != _requestVersion) return;
      emit(
        user == null ? const AuthUnauthenticated() : AuthAuthenticated(user),
      );
    } catch (error) {
      if (isClosed || version != _requestVersion) return;
      emit(AuthFailure('No se pudo cargar tu perfil: $error'));
    }
  }

  Future<void> _signOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    ++_requestVersion;
    emit(const AuthLoading());
    try {
      await _signOut();
      if (!isClosed) emit(const AuthUnauthenticated());
    } catch (error) {
      if (!isClosed) {
        emit(AuthFailure('No se pudo cerrar sesión: $error'));
      }
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await super.close();
  }
}
