import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LectioReservationsPage extends StatelessWidget {
  const LectioReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        title: const Text('Reservas'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0D2B1D),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.bookmark_add_outlined,
                  size: 64,
                  color: Color(0xFF1A6B45),
                ),
                const SizedBox(height: 20),
                Text(
                  'Tus reservas',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.instrumentSerif(
                    color: const Color(0xFF0D2B1D),
                    fontSize: 34,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Aquí podrás consultar y gestionar tus reservas de libros. '
                  'Esta sección estará disponible próximamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6B8377),
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
