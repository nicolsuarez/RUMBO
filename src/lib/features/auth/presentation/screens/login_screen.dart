import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/login/login_bloc.dart';
import '../../../../shared/theme/rumbo_colors.dart';

/// Solo presentación. La autenticación se conectará al caso de uso y a Supabase.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onRegister,
    required this.onBack,
  });

  final VoidCallback onRegister;
  final VoidCallback onBack;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<LoginBloc>().add(
      LoginSubmitted(email: _email.text.trim(), password: _password.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LoginFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
        // LoginSuccess no navega: AuthBloc observa la sesión Supabase.
      },
      builder: (context, state) {
        final busy = state is LoginSubmitting;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Iniciar sesión'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onBack,
            ),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.landscape,
                          size: 48,
                          color: RumboColors.monte,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Qué bueno verte de nuevo',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ingresa a tu cuenta para continuar tu rumbo.',
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) =>
                              value == null ||
                                  !RegExp(
                                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                  ).hasMatch(value.trim())
                              ? 'Ingresa un correo válido'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Ingresa tu contraseña'
                              : null,
                        ),
                        const SizedBox(height: 26),
                        FilledButton(
                          onPressed: busy ? null : _submit,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                          child: Text(
                            busy ? 'Ingresando...' : 'Iniciar sesión',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: busy ? null : widget.onRegister,
                            child: const Text('¿No tienes cuenta? Regístrate'),
                          ),
                        ),
                      ],
                    ),
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
