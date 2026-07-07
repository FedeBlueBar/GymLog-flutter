import 'package:flutter/material.dart';

/// Card mostrata nella dashboard principale che evidenzia l'allenamento previsto per la giornata odierna.
/// Include un pulsante rapido per iniziare o riprendere l'allenamento.
class WorkoutTodayCard extends StatelessWidget {
  /// Il nome della scheda di allenamento di oggi (es. "Push", "Gambe"), 
  /// oppure null se è un giorno di riposo.
  final String? nomeWorkout;
  
  /// Indica se l'utente ha già un allenamento in corso (non ancora terminato).
  /// In tal caso il pulsante mostrerà "Riprendi" invece di "Inizia".
  final bool hasActiveWorkout;
  
  /// Funzione chiamata quando si preme il pulsante o l'intera card.
  final VoidCallback onAvviaAllenamento;

  const WorkoutTodayCard({
    super.key,
    required this.nomeWorkout,
    this.hasActiveWorkout = false,
    required this.onAvviaAllenamento,
  });

  @override
  Widget build(BuildContext context) {
    // Verifica se c'è effettivamente un allenamento da mostrare
    final hasWorkout = nomeWorkout != null;

    // Utilizza una Card per racchiudere i contenuti
    return Card(
      margin: EdgeInsets.zero, // Nessun margine esterno per allinearsi al layout genitore
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Bordi ampiamente arrotondati
      ),
      color: const Color(0xFFF6F5F8), // Colore di sfondo grigio chiarissimo
      elevation: 0, // Design piatto senza ombre
      // InkWell permette di gestire il tocco sull'intera card mostrando l'effetto splash
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        // Permette di tappare l'intera card per avviare l'allenamento (se presente)
        onTap: onAvviaAllenamento,
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Padding interno attorno ai testi e pulsante
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Testi allineati a sinistra
            children: [
              // Riga con Icona e Titolo principale
              Row(
                children: [
                  const Icon(
                    Icons.fitness_center,
                    size: 24,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Workout di oggi",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Mostra il nome dell'allenamento. Se è null mostra un testo di default
              Text(
                nomeWorkout ?? "Nessun allenamento programmato",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87, // Testo leggermente smorzato
                ),
              ),
              const SizedBox(height: 12),
              // Pulsante dedicato ad iniziare o riprendere l'allenamento
              ElevatedButton(
                // Il bottone è disabilitato (passando null) se non c'è un allenamento programmato per oggi
                onPressed: hasWorkout ? onAvviaAllenamento : null,
                style: ElevatedButton.styleFrom(
                  // Cambia colore: rosso se l'utente ha già un workout attivo, altrimenti nero
                  backgroundColor: hasActiveWorkout ? Colors.red : Colors.black,
                  foregroundColor: Colors.white, // Colore del testo
                  // Colori applicati automaticamente quando onPressed è null
                  disabledBackgroundColor: const Color.fromRGBO(0, 0, 0, 0.5),
                  disabledForegroundColor: const Color.fromRGBO(255, 255, 255, 0.5),
                  elevation: 0,
                  shape: const StadiumBorder(), // Bottone completamente arrotondato ai lati
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min, // La riga occupa solo lo spazio necessario
                  children: [
                    const Icon(Icons.play_arrow, size: 18),
                    const SizedBox(width: 4),
                    // Etichetta contestuale: "Riprendi" o "Inizia"
                    Text(hasActiveWorkout ? "Riprendi" : "Inizia"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
