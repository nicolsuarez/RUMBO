import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/register_draft.dart';
import '../../../domain/usecases/auth_usecases.dart';
import '../../../domain/usecases/check_username_availability_usecase.dart';

part 'register_event.dart';
part 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc({
    required SignUpUseCase signUp,
    required CheckUsernameAvailabilityUseCase checkUsername,
  }) : _signUp = signUp,
       _checkUsername = checkUsername,
       super(const RegisterInitial()) {
    on<RegisterSubmitted>(_onSubmitted);
    on<RegisterUsernameCheckRequested>(_onUsernameCheck);
  }

  final SignUpUseCase _signUp;
  final CheckUsernameAvailabilityUseCase _checkUsername;

  Future<void> _onUsernameCheck(
    RegisterUsernameCheckRequested event,
    Emitter<RegisterState> emit,
  ) async {
    if (state is RegisterSubmitting || state is RegisterUsernameChecking) {
      return;
    }

    final username = event.username.trim().toLowerCase();

    emit(RegisterUsernameChecking(username));

    try {
      final available = await _checkUsername(username);

      if (available) {
        emit(RegisterUsernameAvailable(username));
      } else {
        emit(RegisterUsernameTaken(username));
      }
    } catch (_) {
      emit(
        const RegisterUsernameCheckFailure(
          'No se pudo verificar el nombre de usuario. '
          'Comprueba tu conexión e inténtalo de nuevo.',
        ),
      );
    }
  }

  Future<void> _onSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    if (state is RegisterSubmitting) return;

    emit(const RegisterSubmitting());

    try {
      final requiresEmailConfirmation = await _signUp(event.draft);

      emit(
        RegisterSuccess(requiresEmailConfirmation: requiresEmailConfirmation),
      );
    } catch (error) {
      emit(RegisterFailure('No se completó el registro: $error'));
    }
  }
}
