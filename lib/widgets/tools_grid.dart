import 'package:flutter/material.dart';

/// Modello dati interno per configurare ogni singolo strumento ("tool") mostrato nella griglia.
class ToolItem {
  /// Nome dello strumento (es. "Allenamento").
  final String label;
  
  /// Icona associata allo strumento.
  final IconData icon;
  
  /// Colore di sfondo del quadrato che contiene l'icona.
  final Color containerColor;
  
  /// Colore dell'icona stessa.
  final Color iconColor;
  
  /// Funzione da eseguire al tap sulla card.
  final VoidCallback onClick;

  const ToolItem({
    required this.label,
    required this.icon,
    required this.containerColor,
    required this.iconColor,
    required this.onClick,
  });
}

/// Widget che mostra una griglia (2 colonne) di strumenti/scorciatoie principali dell'app.
/// Usato tipicamente nella Home (Dashboard).
class ToolsGrid extends StatelessWidget {
  /// Callback per navigare alla sezione Allenamento.
  final VoidCallback onAllenamento;
  /// Callback per navigare alla sezione Dieta (se implementata).
  final VoidCallback onDieta;
  
  /// Callback per navigare alla Community.
  final VoidCallback onCommunity;
  
  /// Callback per visualizzare i Progressi.
  final VoidCallback onProgressi;

  const ToolsGrid({
    super.key,
    required this.onAllenamento,
    required this.onDieta,
    required this.onCommunity,
    required this.onProgressi,
  });

  @override
  Widget build(BuildContext context) {
    // Definizione statica degli strumenti (tools) disponibili nella griglia.
    // Ogni strumento ha una label, un'icona, dei colori tematici e un'azione associata.
    final tools = [
      ToolItem(
        label: "Allenamento",
        icon: Icons.fitness_center_rounded,
        containerColor: const Color(0xFFEBE5FF), // Sfondo lilla chiaro
        iconColor: const Color(0xFF6C5CE7), // Icona viola scuro
        onClick: onAllenamento,
      ),
      ToolItem(
        label: "Dieta",
        icon: Icons.restaurant_rounded,
        containerColor: const Color(0xFFE8F8F5), // Sfondo verde acqua chiaro
        iconColor: const Color(0xFF16A085), // Icona verde acqua scuro
        onClick: onDieta,
      ),
      ToolItem(
        label: "Community",
        icon: Icons.group_rounded,
        containerColor: const Color(0xFFFFF4E6), // Sfondo arancione chiaro
        iconColor: const Color(0xFFE67E22), // Icona arancione scuro
        onClick: onCommunity,
      ),
      ToolItem(
        label: "Progressi",
        icon: Icons.show_chart_rounded,
        containerColor: const Color(0xFFFCEBE6), // Sfondo rosso/arancio chiaro
        iconColor: const Color(0xFFD35400), // Icona rosso/arancio scuro
        onClick: onProgressi,
      ),
    ];

    // Utilizziamo una GridView per mostrare gli elementi in un layout a griglia bidimensionale.
    return GridView.builder(
      // shrinkWrap a true permette alla griglia di occupare solo lo spazio necessario
      // e non espandersi all'infinito (utile se inserita in altri scroll view)
      shrinkWrap: true,
      // Disabilita lo scroll interno alla griglia: lo scroll sarà gestito dalla vista genitore
      physics: const NeverScrollableScrollPhysics(),
      // Configurazione delle righe e colonne
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Numero di colonne fisse (2)
        crossAxisSpacing: 12, // Spazio orizzontale tra gli elementi
        mainAxisSpacing: 12, // Spazio verticale tra gli elementi
        childAspectRatio: 1.3, // Rapporto larghezza/altezza delle card (più larghe che alte)
      ),
      itemCount: tools.length, // Numero totale di elementi da renderizzare
      itemBuilder: (context, index) {
        final tool = tools[index];
        // Ogni elemento della griglia è rappresentato da una Card cliccabile
        return Card(
          margin: EdgeInsets.zero, // Margine gestito dallo spacing della gridDelegate
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: const Color(0xFFF6F5F8), // Colore di sfondo di ogni singola card
          elevation: 0, // Nessuna ombra per un look piatto (flat design)
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: tool.onClick, // Azione eseguita al tap
            child: Padding(
              padding: const EdgeInsets.all(16.0), // Padding interno della card
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Centra verticalmente il contenuto
                children: [
                  // Contenitore colorato che fa da sfondo all'icona dello strumento
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: tool.containerColor, // Colore di sfondo personalizzato dal ToolItem
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    // L'icona effettiva del tool
                    child: Icon(
                      tool.icon,
                      color: tool.iconColor, // Colore dell'icona personalizzato
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12), // Spazio tra l'icona e il testo
                  // Testo con il nome dello strumento
                  Text(
                    tool.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
