// Questo file contiene il modello dati per il piano di allenamento temporale (Split Plan).
// Serve a gestire la programmazione settimanale o mensile, indicando quale 
// scheda va eseguita in determinati giorni e gestendo i giorni di riposo o le eccezioni.

// Modello che rappresenta la pianificazione (o calendario) delle schede di allenamento.
// Definisce le date di validità del programma, la divisione base dei giorni (split) 
// e le eventuali sovrascritture per date specifiche (overrides).
class SplitPlan {
  // Date di inizio e fine del programma (generalmente salvate come timestamp in millisecondi)
  final int startDate;
  final int endDate;

  // Calendario settimanale standard: mappa un giorno (es. 1 per Lunedì, o giorno 1 del ciclo) all'ID della scheda.
  final Map<int, String> split;

  // Eccezioni specifiche: mappa una data esatta (in formato stringa) all'ID di una scheda,
  // sovrascrivendo la normale programmazione per quel giorno (es. se un giorno mi alleno invece di riposare).
  final Map<String, String> overrides;

  SplitPlan({
    this.startDate = 0,
    this.endDate = 0,
    this.split = const {},
    this.overrides = const {},
  });

  // Crea un'istanza partendo dai dati salvati nel database (in formato Mappa JSON).
  // Include la logica fondamentale per convertire le chiavi delle mappe (che nel JSON sono obbligatoriamente stringhe)
  // nei formati originali corretti (interi per 'split').
  factory SplitPlan.fromMap(Map<String, dynamic> map) {
    final rawSplit = map['split'] as Map?;
    final splitMap = <int, String>{};
    if (rawSplit != null) {
      rawSplit.forEach((k, v) {
        final keyInt = int.tryParse(k.toString());
        if (keyInt != null) {
          splitMap[keyInt] = v.toString();
        }
      });
    }

    final rawOverrides = map['overrides'] as Map?;
    final overridesMap = <String, String>{};
    if (rawOverrides != null) {
      rawOverrides.forEach((k, v) {
        overridesMap[k.toString()] = v.toString();
      });
    }

    return SplitPlan(
      startDate: (map['startDate'] as num?)?.toInt() ?? 0,
      endDate: (map['endDate'] as num?)?.toInt() ?? 0,
      split: splitMap,
      overrides: overridesMap,
    );
  }

  // Converte l'oggetto in una Mappa (JSON) per poterlo salvare su database come Firestore.
  /// Trasforma le chiavi intere della mappa 'split' in stringhe per rispettare gli standard JSON.
  Map<String, dynamic> toMap() {
    final splitStringMap = split.map((k, v) => MapEntry(k.toString(), v));
    return {
      'startDate': startDate,
      'endDate': endDate,
      'split': splitStringMap,
      'overrides': overrides,
    };
  }

  // Crea una copia esatta del piano attuale permettendo di modificare solo campi specifici.
  // (Molto utile per gestire l'aggiornamento dell'interfaccia utente in modo immutabile).
  SplitPlan copyWith({
    int? startDate,
    int? endDate,
    Map<int, String>? split,
    Map<String, String>? overrides,
  }) {
    return SplitPlan(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      split: split ?? this.split,
      overrides: overrides ?? this.overrides,
    );
  }
}
