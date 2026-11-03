import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/auth_usecases.dart';

part 'login_event.dart';
part 'login_state.dart';

/// Estado del intento de ingreso. AuthBloc gestiona la sesión global.
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({required SignInUseCase signIn})
    : _signIn = signIn,
      super(const LoginInitial()) {
    on<LoginSubmitted>(_onSubmitted);
  }

  final SignInUseCase _signIn;

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    if (state is LoginSubmitting) return;
    emit(const LoginSubmitting());
    try {
      await _signIn(event.email.trim(), event.password);
      emit(const LoginSuccess());
    } catch (error) {
      emit(LoginFailure('No se pudo iniciar sesión: $error'));
    }
  }
}
