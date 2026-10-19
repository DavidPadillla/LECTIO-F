import 'package:flutter/material.dart';

import '../data/lectio_auth_service.dart';

class LectioMemberPage extends StatelessWidget {
  const LectioMemberPage({super.key, required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF27AE60);
    const navy = Color(0xFF2C3E50);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: navy,
        title: const Text('Mi biblioteca'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 36,
                backgroundColor: Color(0xFFE5F5EC),
                child: Icon(Icons.check, color: green, size: 38),
              ),
              const SizedBox(height: 20),
              Text(
                '¡Hola, ${session.username}!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: navy,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Has iniciado sesión correctamente en Lectio Biblioteca.',
                textAlign: TextAlign.center,
                style: TextStyle(color: navy, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
