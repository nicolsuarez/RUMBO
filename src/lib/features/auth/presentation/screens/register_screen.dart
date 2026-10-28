import 'package:flutter/material.dart';

import '../pages/register_credentials_page.dart';
import '../pages/register_personal_info_page.dart';
import '../pages/register_interests_page.dart';
import '../../domain/entities/register_draft.dart';
import '../../domain/usecases/auth_usecases.dart';

/// Registro multipágina; se conecta a Supabase mediante SignUpUseCase.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.onLogin, required this.signUp});
  final VoidCallback onLogin;
  final SignUpUseCase signUp;

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
  bool _busy = false;
  final Set<String> _interests = {};
  int _page = 0;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in [_email, _password, _confirmation, _name, _phone, _username]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context, initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900), lastDate: DateTime(now.year - 18, now.month, now.day));
    if (date != null) setState(() => _birthDate = date);
  }

  Future<void> _next() async {
    if (_busy) return;
    if (!(_forms[_page].currentState?.validate() ?? false)) return;
    if (_page == 0 && !_acceptTerms) {
      _message('Acepta los términos y la política de privacidad para continuar.');
      return;
    }
    if (_page == 1 && _birthDate == null) {
      _message('Selecciona tu fecha de nacimiento. Debes ser mayor de 18 años.');
      return;
    }
    if (_page == 2) {
      if (_interests.isEmpty) {
        _message('Selecciona al menos un interés.');
        return;
      }
      setState(() => _busy = true);
      try {
        final verifyEmail = await widget.signUp(RegisterDraft(
          email: _email.text.trim(), password: _password.text,
          name: _name.text.trim(), phone: _phone.text.trim(),
          username: _username.text.trim(), birthDate: _birthDate!,
          interests: _interests.toList(),
        ));
        if (!mounted) return;
        _message(verifyEmail
          ? 'Revisa tu correo y confirma la cuenta antes de iniciar sesión.'
          : 'Cuenta creada correctamente.');
        widget.onLogin();
      } catch (error) {
        if (mounted) _message('No se completó el registro: $error');
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }
    _pageController.nextPage(duration: const Duration(milliseconds: 240), curve: Curves.easeInOut);
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Paso ${_page + 1} de 3', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: (_page + 1) / 3),
                  const SizedBox(height: 16),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) => setState(() => _page = index),
                      children: [
                        Form(key: _forms[0], child: RegisterCredentialsPage(
                          email: _email, password: _password, confirmation: _confirmation,
                          acceptTerms: _acceptTerms,
                          onTermsChanged: (value) => setState(() => _acceptTerms = value),
                        )),
                        Form(key: _forms[1], child: RegisterPersonalInfoPage(
                          name: _name, phone: _phone, username: _username,
                          birthDate: _birthDate, onPickBirthDate: _pickBirthDate,
                        )),
                        Form(key: _forms[2], child: RegisterInterestsPage(
                          selected: _interests,
                          onChanged: (interest, selected) => setState(() {
                            if (selected) { _interests.add(interest); } else { _interests.remove(interest); }
                          }),
                        )),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (_page > 0)
                        TextButton(
                          onPressed: () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 240), curve: Curves.easeInOut),
                          child: const Text('Anterior'),
                        ),
                      const Spacer(),
                      FilledButton(
                        onPressed: _busy ? null : _next,
                        child: Text(_busy ? 'Registrando...' : (_page == 2 ? 'Finalizar registro' : 'Siguiente')),
                      ),
                    ],
                  ),
                  Center(child: TextButton(onPressed: widget.onLogin, child: const Text('¿Ya tienes cuenta? Inicia sesión'))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
