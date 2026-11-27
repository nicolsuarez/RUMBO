import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../domain/entities/emergency_contact.dart';
import '../bloc/emergency_contact_bloc.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EmergencyContactBloc>(
      create: (_) =>
          locator<EmergencyContactBloc>()
            ..add(const EmergencyContactsLoadRequested()),
      child: const _EmergencyContactsView(),
    );
  }
}

class _EmergencyContactsView extends StatelessWidget {
  const _EmergencyContactsView();

  Future<void> _showContactForm(
    BuildContext context, {
    EmergencyContact? contact,
  }) async {
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (_) => _EmergencyContactFormDialog(contact: contact),
    );

    if (result == null || !context.mounted) {
      return;
    }

    final bloc = context.read<EmergencyContactBloc>();
    final name = result['name'] ?? '';
    final phone = result['phone'] ?? '';
    final relationship = result['relationship'];

    if (contact != null) {
      bloc.add(
        EmergencyContactUpdateRequested(
          id: contact.id,
          name: name,
          phone: phone,
          relationship: relationship,
        ),
      );
    } else {
      bloc.add(
        EmergencyContactCreateRequested(
          name: name,
          phone: phone,
          relationship: relationship,
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    EmergencyContact contact,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar contacto'),
          content: Text('¿Deseas eliminar a ${contact.name} de tus contactos?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      context.read<EmergencyContactBloc>().add(
        EmergencyContactDeleteRequested(contact.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contactos de emergencia')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showContactForm(context),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Agregar contacto'),
      ),
      body: BlocConsumer<EmergencyContactBloc, EmergencyContactState>(
        listener: (context, state) {
          if (state.message != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message!)));
          }

          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.loading && state.contacts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.contacts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.contact_phone_outlined, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'No tienes contactos registrados.',
                      textAlign: TextAlign.center,
                    ),
                    if (state.error != null) ...[
                      const SizedBox(height: 12),
                      Text(state.error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          context.read<EmergencyContactBloc>().add(
                            const EmergencyContactsLoadRequested(),
                          );
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                children: [
                  const Text(
                    'Personas de confianza',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...state.contacts.map((contact) {
                    final relationship = contact.relationship?.trim();

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            contact.name.isEmpty
                                ? '?'
                                : contact.name[0].toUpperCase(),
                          ),
                        ),
                        title: Text(contact.name),
                        subtitle: Text(
                          [
                            contact.phone,
                            if (relationship != null && relationship.isNotEmpty)
                              relationship,
                          ].join(' · '),
                        ),
                        trailing: PopupMenuButton<String>(
                          enabled: !state.busy,
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showContactForm(context, contact: contact);
                            } else if (value == 'delete') {
                              _confirmDelete(context, contact);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Editar')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Eliminar'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
              if (state.busy)
                const Align(
                  alignment: Alignment.topCenter,
                  child: LinearProgressIndicator(),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _EmergencyContactFormDialog extends StatefulWidget {
  const _EmergencyContactFormDialog({this.contact});

  final EmergencyContact? contact;

  @override
  State<_EmergencyContactFormDialog> createState() =>
      _EmergencyContactFormDialogState();
}

class _EmergencyContactFormDialogState
    extends State<_EmergencyContactFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _relationshipController;

  bool get _isEditing => widget.contact != null;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.contact?.name ?? '');

    _phoneController = TextEditingController(text: widget.contact?.phone ?? '');

    _relationshipController = TextEditingController(
      text: widget.contact?.relationship ?? '',
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final relationship = _relationshipController.text.trim();

    final result = <String, String?>{
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'relationship': relationship.isEmpty ? null : relationship,
    };

    Navigator.of(context).pop(result);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Editar contacto' : 'Nuevo contacto'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                maxLength: 100,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el nombre.';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneController,
                maxLength: 20,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el teléfono.';
                  }

                  final phone = value.trim();
                  final validFormat = RegExp(
                    r'^\+?[0-9 ()-]+$',
                  ).hasMatch(phone);
                  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');

                  if (!validFormat || digits.length < 7 || digits.length > 15) {
                    return 'Ingresa un teléfono válido.';
                  }

                  return null;
                },
              ),
              TextFormField(
                controller: _relationshipController,
                maxLength: 40,
                decoration: const InputDecoration(
                  labelText: 'Parentesco (opcional)',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEditing ? 'Guardar' : 'Registrar'),
        ),
      ],
    );
  }
}
