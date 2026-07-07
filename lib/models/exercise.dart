// Questo file contiene il modello dati per un singolo Esercizio.
// Rappresenta le informazioni base di un esercizio (es. nome) e i relativi 
// parametri di allenamento (serie, ripetizioni, peso), oltre ai dettagli multimediali.

// Modello che definisce le caratteristiche di un esercizio.
// Usato sia per gli esercizi presenti nelle schede di allenamento, sia come
// riferimento dalla libreria globale degli esercizi.
class Exercise {
  // Identificativo e nome dell'esercizio
  String id;
  String name;

  // Parametri di allenamento (salvati come stringhe per flessibilità di input, es. "3x10" o "Cedimento")
  String sets;
  String reps;
  String weight;

  // Risorse multimediali e dettagli anatomici opzionali
  String? gifUrl;
  List<String> instructions;
  String? bodyPart;
  String? target;
  String? youtubeVideoId;

  Exercise({
    this.id = "",
    this.name = "",
    this.sets = "",
    this.reps = "",
    this.weight = "",
    this.gifUrl,
    this.instructions = const [],
    this.bodyPart,
    this.target,
    this.youtubeVideoId,
  });

  /// Crea un'istanza partendo dai dati in formato Mappa (JSON / Firestore).
  // Include una logica per il parsing sicuro della lista di istruzioni.
  factory Exercise.fromMap(Map<String, dynamic> map) {
    List<String> parsedInstructions = [];
    if (map['instructions'] is List) {
      parsedInstructions = (map['instructions'] as List).map((e) => e.toString()).toList();
    } else if (map['instructions'] != null) {
      parsedInstructions = [map['instructions'].toString()];
    }

    return Exercise(
      id: map['id'] ?? "",
      name: map['name'] ?? "",
      sets: map['sets'] ?? "",
      reps: map['reps'] ?? "",
      weight: map['weight'] ?? "",
      gifUrl: map['gifUrl'],
      instructions: parsedInstructions,
      bodyPart: map['bodyPart'],
      target: map['target'],
      youtubeVideoId: map['youtubeVideoId'],
    );
  }

  /// Converte l'oggetto in una Mappa (JSON) pronta per il salvataggio su database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'gifUrl': gifUrl,
      'instructions': instructions,
      'bodyPart': bodyPart,
      'target': target,
      'youtubeVideoId': youtubeVideoId,
    };
  }

  // Restituisce un nuovo oggetto Exercise copiando i dati di quello attuale,
  // con la possibilità di sovrascrivere solo alcuni parametri specifici.
  //  (Molto utile per aggiornare lo stato locale senza mutare l'oggetto originale in modo incontrollato).
  Exercise copyWith({
    String? id,
    String? name,
    String? sets,
    String? reps,
    String? weight,
    String? gifUrl,
    List<String>? instructions,
    String? bodyPart,
    String? target,
    String? youtubeVideoId,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      gifUrl: gifUrl ?? this.gifUrl,
      instructions: instructions ?? this.instructions,
      bodyPart: bodyPart ?? this.bodyPart,
      target: target ?? this.target,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
    );
  }
}
