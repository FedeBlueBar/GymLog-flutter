import 'package:flutter/material.dart';

// Schermata "Segnaposto" (Placeholder).
// Usata per le sezioni dell'app che sono ancora in via di sviluppo.
// Mostra semplicemente un'icona di "lavori in corso" e il titolo della pagina passata.
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barra superiore con il titolo dinamico
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFEBEBEB),
      // Corpo centrale con l'avviso di "Prossimamente"
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction_rounded, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              "$title - Prossimamente",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Questa sezione sarà disponibile a breve.",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
