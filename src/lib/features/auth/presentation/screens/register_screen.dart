import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/register/register_bloc.dart';
import '../pages/register_credentials_page.dart';
import '../pages/register_personal_info_page.dart';
import '../pages/register_interests_page.dart';
import '../../domain/entities/register_draft.dart';

/// Registro multipágina de RUMBO.
/// RegisterBloc gestiona el registro con Supabase.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.onLogin,
    required this.onBack,
    required this.onRegistrationStarted,
    required this.onRegistrationFailed,
  });

  final VoidCallback onLogin;
  final VoidCallback onBack;
  final VoidCallback onRegistrationStarted;
  final VoidCallback onRegistrationFailed;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _pageController = PageController();

  final _forms = List.generate(3, (_) => GlobalKey<FormState>());

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _username = TextEditingController();

  DateTime? _birthDate;
  final Set<String> _interests = {};

  int _page = 0;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _pageController.dispose();

    for (final controller in [
      _email,
      _password,
      _confirmation,
      _name,
      _phone,
      _username,
    ]) {
      controller.dispose();
    }

    super.dispose();
  }

  // Regresar a la página anterior o a Bienvenida.
  void _goBack() {
    if (context.read<RegisterBloc>().state is RegisterSubmitting) {
      return;
    }

    if (_page == 0) {
      widget.onBack();
    } else {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeInOut,
      );
    }
  }

  // Selección de fecha de nacimiento: mínimo 18 años.
  Future<void> _pickBirthDate() async {
    final now = DateTime.now();

    final maxDate = DateTime(now.year - 18, now.month, now.day);

    final date = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? maxDate,
      firstDate: DateTime(1900),
      lastDate: maxDate,
    );

    if (!mounted) return;

    if (date != null) {
      setState(() {
        _birthDate = date;
      });
    }
  }

  // Validación y navegación del registro.
  Future<void> _next() async {
    if (context.read<RegisterBloc>().state is RegisterSubmitting) {
      return;
    }

    if (!(_forms[_page].currentState?.validate() ?? false)) {
      return;
    }

    // Página 1: Credenciales.
    if (_page == 0 && !_acceptTerms) {
      _message(
        'Acepta los términos y la política de privacidad '
        'para continuar.',
      );
      return;
    }

    // Página 2: Datos personales.
    if (_page == 1 && _birthDate == null) {
      _message(
        'Selecciona tu fecha de nacimiento. '
        'Debes tener al menos 18 años.',
      );
      return;
    }

    // Página 2: verificar username antes de avanzar.
    if (_page == 1) {
      context.read<RegisterBloc>().add(
        RegisterUsernameCheckRequested(_username.text.trim()),
      );
      return;
    }

    // Página 3: Intereses y registro definitivo.
    if (_page == 2) {
      if (_interests.isEmpty) {
        _message('Selecciona al menos un interés.');
        return;
      }

      // Notifica a RumboShell que inició un registro.
      // Esto permitirá mostrar el resumen tras la
      // autenticación y carga del perfil real.
      widget.onRegistrationStarted();

      context.read<RegisterBloc>().add(
        RegisterSubmitted(
          RegisterDraft(
            email: _email.text.trim(),
            password: _password.text,
            name: _name.text.trim(),
            phone: _phone.text.trim(),
            username: _username.text.trim(),
            birthDate: _birthDate!,
            interests: _interests.toList(),
          ),
        ),
      );

      return;
    }

    // Avanzar entre páginas internas.
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOut,
    );
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegisterBloc, RegisterState>(
      listener: (context, state) {
        if (state is RegisterUsernameAvailable) {
          // Evita avanzar si el usuario modificó el campo
          // mientras se realizaba la consulta.
          if (_page == 1 &&
              _username.text.trim().toLowerCase() == state.username) {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeInOut,
            );
          }
        }

        if (state is RegisterUsernameTaken) {
          _message(
            'El nombre de usuario "${state.username}" '
            'ya está ocupado. Elige otro.',
          );
        }

        if (state is RegisterUsernameCheckFailure) {
          _message(state.message);
        }

        if (state is RegisterFailure) {
          widget.onRegistrationFailed();
          _message(state.message);
        }

        if (state is RegisterSuccess) {
          if (state.requiresEmailConfirmation) {
            widget.onRegistrationFailed();

            _message(
              'Revisa tu correo y confirma la cuenta '
              'antes de iniciar sesión.',
            );

            widget.onLogin();
          }

          // Si existe sesión, AuthBloc cargará el perfil
          // y RumboShell mostrará el resumen del registro.
        }
      },

      builder: (context, state) {
        final busy =
            state is RegisterSubmitting || state is RegisterUsernameChecking;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Crear cuenta'),
            automaticallyImplyLeading: false,
            leading: _page == 0
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: busy ? null : _goBack,
                  )
                : null,
          ),

          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),

                child: Padding(
                  padding: const EdgeInsets.all(20),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Paso ${_page + 1} de 3',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),

                      const SizedBox(height: 8),

                      LinearProgressIndicator(value: (_page + 1) / 3),

                      const SizedBox(height: 16),

                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),

                          onPageChanged: (index) {
                            setState(() {
                              _page = index;
                            });
                          },

                          children: [
                            // Página 1: Credenciales.
                            Form(
                              key: _forms[0],
                              child: RegisterCredentialsPage(
                                email: _email,
                                password: _password,
                                confirmation: _confirmation,
                                acceptTerms: _acceptTerms,
                                onTermsChanged: (value) {
                                  setState(() {
                                    _acceptTerms = value;
                                  });
                                },
                              ),
                            ),

                            // Página 2: Datos personales.
                            Form(
                              key: _forms[1],
                              child: RegisterPersonalInfoPage(
                                name: _name,
                                phone: _phone,
                                username: _username,
                                birthDate: _birthDate,
                                onPickBirthDate: _pickBirthDate,
                              ),
                            ),

                            // Página 3: Intereses.
                            Form(
                              key: _forms[2],
                              child: RegisterInterestsPage(
                                selected: _interests,
                                onChanged: (interest, selected) {
                                  setState(() {
                                    if (selected) {
                                      _interests.add(interest);
                                    } else {
                                      _interests.remove(interest);
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_page == 1 && state is RegisterUsernameChecking)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text('Comprobando nombre de usuario...'),
                            ],
                          ),
                        ),

                      Row(
                        children: [
                          if (_page > 0)
                            TextButton(
                              onPressed: busy ? null : _goBack,
                              child: const Text('Anterior'),
                            ),

                          const Spacer(),

                          FilledButton(
                            onPressed: busy ? null : _next,
                            child: Text(
                              busy
                                  ? 'Registrando...'
                                  : _page == 2
                                  ? 'Finalizar registro'
                                  : 'Siguiente',
                            ),
                          ),
                        ],
                      ),

                      Center(
                        child: TextButton(
                          onPressed: busy ? null : widget.onLogin,
                          child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
