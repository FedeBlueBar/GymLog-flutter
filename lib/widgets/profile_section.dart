import 'package:flutter/material.dart';

/// Widget che funge da intestazione (titolo) per raggruppare visivamente 
/// più sezioni all'interno della schermata del profilo.
class SectionHeader extends StatelessWidget {
  /// Testo mostrato nell'intestazione (es. "Dati Personali").
  final String testo;

  const SectionHeader({super.key, required this.testo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 24.0, bottom: 8.0),
      child: Text(
        testo.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          letterSpacing: 1.0,
          color: Colors.black54,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Widget che rappresenta una singola riga di informazione all'interno del profilo.
/// Mostra un'icona colorata, un'etichetta (es. "Altezza") e il relativo valore.
/// Supporta anche un'azione al tap tramite il parametro [onClick].
class ProfileInfoRow extends StatelessWidget {
  /// L'icona da mostrare a sinistra.
  final IconData icona;
  
  /// Colore dell'icona (default: viola).
  final Color iconColor;
  
  /// Colore di sfondo del contenitore dell'icona (default: viola chiaro).
  final Color iconBgColor;
  
  /// Etichetta che descrive il dato (es. "Età").
  final String etichetta;
  
  /// Valore del dato mostrato. Se nullo o vuoto, mostra un tratto "—".
  final String? valore;
  
  /// Funzione da eseguire quando l'utente tocca la riga.
  /// Se presente, la riga mostra un'icona "freccia destra" indicando la cliccabilità.
  final VoidCallback? onClick;

  const ProfileInfoRow({
    super.key,
    required this.icona,
    this.iconColor = const Color(0xFF6C5CE7),
    this.iconBgColor = const Color(0xFFEBE5FF),
    required this.etichetta,
    required this.valore,
    this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    final hasClick = onClick != null;
    final rowContent = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              icona,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etichetta,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valore == null || valore!.trim().isEmpty ? "—" : valore!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (hasClick)
            const Icon(
              Icons.keyboard_arrow_right,
              color: Colors.black,
            ),
        ],
      ),
    );

    if (hasClick) {
      return InkWell(
        onTap: onClick,
        child: rowContent,
      );
    } else {
      return rowContent;
    }
  }
}

/// Contenitore stilizzato (Card) che raggruppa più [ProfileInfoRow]
/// per separare logicamente le informazioni nel profilo utente.
class ProfileCard extends StatelessWidget {
  /// Lista di widget (tipicamente [ProfileInfoRow] o [ProfileDivider]) da inserire all'interno.
  final List<Widget> children;

  const ProfileCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFEEEEEE), width: 1),
      ),
      color: const Color(0xFFF6F5F8),
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// Divisore orizzontale utilizzato per separare gli elementi all'interno di una [ProfileCard].
class ProfileDivider extends StatelessWidget {
  const ProfileDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Divider(
        color: Color(0xFFEEEEEE),
        thickness: 1,
        height: 1,
      ),
    );
  }
}
