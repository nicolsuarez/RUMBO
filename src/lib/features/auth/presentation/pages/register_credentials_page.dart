import 'package:flutter/material.dart';

class RegisterCredentialsPage extends StatefulWidget {
  const RegisterCredentialsPage({
    super.key,
    required this.email, required this.password, required this.confirmation,
    required this.acceptTerms, required this.onTermsChanged,
  });
  final TextEditingController email, password, confirmation;
  final bool acceptTerms;
  final ValueChanged<bool> onTermsChanged;

  @override
  State<RegisterCredentialsPage> createState() => _RegisterCredentialsPageState();
}

class _RegisterCredentialsPageState extends State<RegisterCredentialsPage> {
  bool _hidePassword = true;

  String? _validatePassword(String? password) {
    final value = password ?? '';
    if (value.length < 10) return 'Mínimo 10 caracteres';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Incluye al menos una mayúscula';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Incluye al menos un número';
    return null;
  }

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      Text('Datos de acceso', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      const Text('Crea tus credenciales para acceder a RUMBO.'),
      const SizedBox(height: 20),
      TextFormField(
        controller: widget.email, keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        decoration: const InputDecoration(labelText: 'Correo electrónico'),
        validator: (value) => !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((value ?? '').trim())
            ? 'Ingresa un correo válido' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: widget.password, obscureText: _hidePassword,
        decoration: InputDecoration(
          labelText: 'Contraseña',
          suffixIcon: IconButton(
            onPressed: () => setState(() => _hidePassword = !_hidePassword),
            icon: Icon(_hidePassword ? Icons.visibility : Icons.visibility_off),
          ),
        ),
        validator: _validatePassword,
      ),
      const SizedBox(height: 8),
      const Text('Mínimo 10 caracteres, una mayúscula y un número.'),
      const SizedBox(height: 16),
      TextFormField(
        controller: widget.confirmation, obscureText: _hidePassword,
        decoration: const InputDecoration(labelText: 'Confirmar contraseña'),
        validator: (value) => value != widget.password.text ? 'Las contraseñas no coinciden' : null,
      ),
      const SizedBox(height: 16),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: widget.acceptTerms,
        onChanged: (value) => widget.onTermsChanged(value ?? false),
        title: const Text('Acepto los términos y la política de privacidad'),
        subtitle: const Text('Los documentos legales deben estar disponibles antes del registro real.'),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    ],
  );
}
