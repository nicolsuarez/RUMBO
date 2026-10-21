import 'package:flutter/material.dart';

import '../../../../shared/theme/rumbo_colors.dart';
import '../../../plans/presentation/models/plan.dart';

class ChatScreen extends StatefulWidget {
  final Plan plan;

  const ChatScreen({super.key, required this.plan});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final controller = TextEditingController();

  final messages = <(String, String, bool)>[
    (
      'Laura',
      '¿Todos llevamos impermeable? '
          'El clima está cambiando mucho.',
      false,
    ),
    (
      'Andrés',
      'Sí, mejor llevar uno liviano. '
          'También linterna frontal.',
      false,
    ),
    (
      'Tú',
      'Listo. Nos vemos en el punto '
          'de encuentro 🙌',
      true,
    ),
  ];

  void sendMessage() {
    final text = controller.text.trim();

    if (text.isEmpty) return;

    setState(() {
      messages.add(('Tú', text, true));
      controller.clear();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.plan.titulo,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text(
              '${widget.plan.van} personas · '
              'organiza '
              '${widget.plan.organizador.split(' ').first}',
              style: const TextStyle(fontSize: 11.5, color: RumboColors.musgo),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          // Lista de mensajes.
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: messages.map((message) {
                final isMine = message.$3;

                return Align(
                  alignment: isMine
                      ? Alignment.centerRight
                      : Alignment.centerLeft,

                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 10,
                    ),
                    constraints: const BoxConstraints(maxWidth: 300),
                    decoration: BoxDecoration(
                      color: isMine
                          ? RumboColors.monte
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre del remitente.
                        if (!isMine)
                          Text(
                            message.$1,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: RumboColors.guayacan,
                            ),
                          ),

                        // Contenido del mensaje.
                        Text(
                          message.$2,
                          style: TextStyle(color: isMine ? Colors.white : null),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Campo para escribir mensajes.
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'Escribe al grupo…',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),

                  const SizedBox(width: 8),

                  IconButton.filled(
                    onPressed: sendMessage,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
