import 'package:flutter/material.dart';

/// Widget a forma di "card" usato per mostrare statistiche visive riassuntive
/// (es. Peso, Altezza, Numero di allenamenti).
class StatCard extends StatelessWidget {
  /// Titolo della statistica (es. "PESO").
  final String titolo;
  
  /// Valore principale da mostrare in grande (es. "75").
  final String valore;
  
  /// Icona mostrata in alto a sinistra.
  final IconData icona;
  
  /// Azione eseguita al tap sulla card.
  final VoidCallback onClick;
  
  /// (Opzionale) Un valore secondario o obiettivo da mostrare accanto al valore principale (es. "/ 80 kg").
  final String? valoreObiettivo;
  
  /// (Opzionale) Un piccolo testo aggiuntivo posto in basso (es. "Ancora 5 kg al traguardo").
  final String? sottotitolo;
  
  /// (Opzionale) Un valore da 0.0 a 1.0 che disegna una barra di progresso orizzontale.
  final double? progress;

  const StatCard({
    super.key,
    required this.titolo,
    required this.valore,
    required this.icona,
    required this.onClick,
    this.valoreObiettivo,
    this.sottotitolo,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    // Utilizziamo una Card per l'effetto contenitore, azzerando l'elevation per un design piatto
    return Card(
      margin: EdgeInsets.zero, // Nessun margine esterno di default
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Bordi arrotondati della card
      ),
      color: const Color(0xFFF6F5F8), // Colore di sfondo grigio chiarissimo
      elevation: 0,
      // InkWell permette di gestire i tocchi (tap) mostrando un effetto visivo "splash"
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onClick,
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Spazio interno tra il bordo e i contenuti
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Allinea tutto a sinistra
            children: [
              // 1. Icona in alto a sinistra
              Icon(
                icona,
                size: 20,
                color: Colors.black,
              ),
              const SizedBox(height: 12),
              // 2. Titolo descrittivo della card (es. "PESO")
              Text(
                titolo,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54, // Colore leggermente smorzato
                ),
              ),
              const SizedBox(height: 4),
              // 3. Riga che contiene il valore principale e, opzionalmente, l'obiettivo
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic, // Allinea i testi sulla stessa linea di base
                children: [
                  // Valore primario (es. "75")
                  Text(
                    valore,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  // Se l'obiettivo è fornito, lo mostriamo accanto al valore primario
                  if (valoreObiettivo != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      valoreObiettivo!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
              // Spacer spinge il contenuto successivo verso il basso della card
              const Spacer(),
              // 4. Se fornito, mostra una barra di avanzamento lineare
              if (progress != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3), // Arrotonda le estremità della barra
                  child: LinearProgressIndicator(
                    value: progress, // Valore compreso tra 0.0 e 1.0
                    minHeight: 6, // Spessore della barra
                    backgroundColor: Colors.black12, // Colore della parte non riempita
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.black), // Colore della parte riempita
                  ),
                ),
                const SizedBox(height: 4),
              ],
              // 5. Se fornito, mostra un sottotitolo esplicativo in basso
              if (sottotitolo != null) ...[
                const SizedBox(height: 4),
                Text(
                  sottotitolo!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
