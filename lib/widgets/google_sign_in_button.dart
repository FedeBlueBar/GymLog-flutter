import 'package:flutter/material.dart';

/// CustomPainter che disegna programmaticamente il logo di Google.
/// Evita la necessità di caricare un asset immagine esterno, migliorando le performance
/// e mantenendo l'app leggera.
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Calcola le dimensioni base: larghezza, altezza e raggio per il cerchio
    final double w = size.width;
    final double h = size.height;
    final double radius = w / 2;
    // Calcola il punto centrale del canvas per posizionare il logo
    final center = Offset(w / 2, h / 2);

    // Imposta lo stile della pittura per gli archi (i bordi colorati del logo G)
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.22 // Spessore del tratto proporzionale alla larghezza
      ..strokeCap = StrokeCap.butt; // Terminazione netta per gli archi

    // Disegna l'arco Rosso (in alto)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - paint.strokeWidth / 2),
      -2.3, // Angolo di inizio
      1.25, // Estensione
      false,
      paint,
    );

    // Disegna l'arco Giallo (a sinistra)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - paint.strokeWidth / 2),
      -3.55,
      1.25,
      false,
      paint,
    );

    // Disegna l'arco Verde (in basso)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - paint.strokeWidth / 2),
      -4.8,
      1.25,
      false,
      paint,
    );

    // Disegna l'arco Blu (a destra, la parte inferiore della barra)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - paint.strokeWidth / 2),
      -1.05,
      1.05,
      false,
      paint,
    );

    // Imposta la pittura per riempire la barra orizzontale centrale (di colore Blu)
    final crossbarPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    // Disegna il rettangolo che forma la traversa della "G"
    canvas.drawRect(
      Rect.fromLTRB(
        w / 2, // Inizia dal centro
        h / 2 - paint.strokeWidth / 2, // Allineata in alto
        w - paint.strokeWidth / 3, // Si estende verso destra
        h / 2 + paint.strokeWidth / 2, // Allineata in basso
      ),
      crossbarPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bottone standardizzato per il login tramite Google.
/// Implementa uno stato di caricamento e integra il logo disegnato tramite [GoogleLogoPainter].
class GoogleSignInButton extends StatelessWidget {
  /// Callback invocato quando l'utente preme il bottone.
  final VoidCallback onPressed;
  
  /// Se true, disabilita il bottone e mostra un indicatore di caricamento.
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // Utilizza un OutlinedButton per dare uno stile bordato e pulito
    return OutlinedButton(
      // Se è in caricamento, disabilita il bottone passando null
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black, // Colore del testo o icone di default
        side: const BorderSide(color: Colors.grey), // Bordo grigio
        minimumSize: const Size(double.infinity, 50), // Larghezza massima e altezza 50
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4), // Angoli leggermente arrotondati
        ),
      ),
      // Contenuto dinamico basato sullo stato isLoading
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              // Mostra un caricatore circolare nero quando in caricamento
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.black,
              ),
            )
          : Row(
              // Centra il contenuto del bottone orizzontalmente
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Usa il CustomPainter per disegnare il logo di Google (20x20)
                CustomPaint(
                  size: const Size(20, 20),
                  painter: GoogleLogoPainter(),
                ),
                // Spazio tra il logo e il testo
                const SizedBox(width: 12),
                // Testo principale del bottone
                const Text(
                  "Continua con Google",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
    );
  }
}
