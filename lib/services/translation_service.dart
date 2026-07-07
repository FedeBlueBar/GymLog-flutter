import 'dart:convert';
import 'package:http/http.dart' as http;

/// Servizio che si occupa della traduzione dei testi (es. nomi e dettagli degli esercizi)
/// utilizzando l'API di MyMemory e dizionari locali per termini specifici del fitness.
class TranslationService {
  // URL base per le chiamate HTTP all'API di traduzione MyMemory
  static const String _baseUrl = "https://api.mymemory.translated.net";
  
  // Cache in memoria per evitare di richiedere più volte la traduzione della stessa stringa
  final Map<String, String> _cache = {};

  static const Map<String, String> _localFitnessTranslations = {
    "panca": "bench",
    "petto": "chest",
    "spalle": "shoulder",
    "schiena": "back",
    "gambe": "leg",
    "cosce": "thigh",
    "polpacci": "calf",
    "braccia": "arm",
    "bicipiti": "bicep",
    "tricipiti": "tricep",
    "addome": "crunch",
    "addominali": "crunch",
    "fianchi": "waist",
    "glutei": "glute",
    "dorsali": "lat",
    "trapezi": "trap",
    "trazioni": "pull up",
    "flessioni": "push up",
    "piegamenti": "push up",
    "affondi": "lunge",
    "alzate": "raise",
    "distensioni": "press",
    "tirate": "row",
    "iperestensioni": "hyperextension",
    "avambracci": "forearm",
    "collo": "neck"
  };

  /// Metodo che prova a tradurre una query inserita dall'utente (in italiano) 
  /// verso l'inglese utilizzando il dizionario locale predefinito. 
  /// Utile per filtrare la ricerca sull'API degli esercizi (che è in inglese).
  String getLocalTranslation(String query) {
    final lowercaseQuery = query.toLowerCase().trim();
    // Se la query intera è nel dizionario, restituisce direttamente la traduzione
    if (_localFitnessTranslations.containsKey(lowercaseQuery)) {
      return _localFitnessTranslations[lowercaseQuery]!;
    }

    // Se è una frase, traduce le singole parole presenti nel dizionario
    final words = lowercaseQuery.split(RegExp(r'\s+'));
    final translatedWords = words.map((word) {
      return _localFitnessTranslations[word] ?? word;
    });
    return translatedWords.join(" ");
  }

  /// Pulisce una stringa in inglese (tipicamente il nome di un esercizio tradotto 
  /// approssimativamente) rimuovendo parentesi, caratteri speciali e, 
  /// se presente, la 's' finale (plurali) per agevolare una ricerca più ampia.
  String cleanEnglishQuery(String translated) {
    var cleaned = translated
        .replaceAll(RegExp(r'\(.*?\)'), "") // Rimuove il testo tra parentesi tonde
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), "") // Rimuove la punteggiatura
        .trim()
        .toLowerCase();

    // Rimuove la 's' finale (es. "crunches" -> "crunch", ma non "press")
    if (cleaned.endsWith("s") && !cleaned.endsWith("ss") && !cleaned.endsWith("us") && cleaned.length > 3) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    return cleaned;
  }

  /// Richiede la traduzione asincrona di una stringa [text] usando l'API di MyMemory.
  /// [langPair] definisce la combinazione di lingue, di default "en|it" (Inglese -> Italiano).
  Future<String> translateText(String text, {String langPair = "en|it"}) async {
    if (text.trim().isEmpty) return text;

    // Controlla se la traduzione è già presente in cache
    final cacheKey = "$langPair:$text";
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final query = Uri.encodeComponent(text);
      final url = Uri.parse("$_baseUrl/get?q=$query&langpair=$langPair");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map parsed = json.decode(response.body);
        final responseData = parsed['responseData'] as Map?;
        final translatedText = responseData?['translatedText']?.toString();
        // Se la traduzione ha successo, salva in cache e restituisce
        if (translatedText != null && translatedText.trim().isNotEmpty) {
          _cache[cacheKey] = translatedText;
          return translatedText;
        }
      }
    } catch (_) {}
    
    // In caso di errore o assenza di traduzione, restituisce il testo originale
    return text;
  }

  /// Metodo per tradurre in batch una lista di stringhe ([texts]).
  /// Unisce le stringhe non presenti in cache separandole da \n e richiede
  /// una singola traduzione cumulativa all'API (ottimizzazione delle chiamate).
  Future<List<String>> translateTexts(List<String> texts, {String langPair = "en|it"}) async {
    if (texts.isEmpty) return [];

    final results = List<String>.filled(texts.length, "");
    final uncachedIndices = <int>[];
    final uncachedTexts = <String>[];

    // Controlla prima quali elementi sono già presenti in cache
    for (int i = 0; i < texts.length; i++) {
      final text = texts[i];
      final cacheKey = "$langPair:$text";
      if (_cache.containsKey(cacheKey)) {
        results[i] = _cache[cacheKey]!;
      } else {
        uncachedIndices.add(i);
        uncachedTexts.add(text);
      }
    }

    // Se tutte le stringhe sono già tradotte, ritorna direttamente
    if (uncachedTexts.isEmpty) {
      return results;
    }

    try {
      // Unisce le stringhe per fare una sola chiamata HTTP
      final joinedText = uncachedTexts.join("\n");
      final query = Uri.encodeComponent(joinedText);
      final url = Uri.parse("$_baseUrl/get?q=$query&langpair=$langPair");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map parsed = json.decode(response.body);
        final responseData = parsed['responseData'] as Map?;
        final translatedJoined = responseData?['translatedText']?.toString();

        if (translatedJoined != null && translatedJoined.trim().isNotEmpty) {
          final translatedLines = translatedJoined.split("\n").map((e) => e.trim()).toList();
          // Verifica che il numero di righe restituite corrisponda
          if (translatedLines.length == uncachedTexts.length) {
            for (int i = 0; i < translatedLines.length; i++) {
              final origText = uncachedTexts[i];
              final cacheKey = "$langPair:$origText";
              _cache[cacheKey] = translatedLines[i]; // Salva in cache

              final origIndex = uncachedIndices[i];
              results[origIndex] = translatedLines[i]; // Ricompone l'ordine
            }
            return results;
          }
        }
      }
    } catch (_) {}

    // Fallback in caso di fallimento della chiamata in batch: tenta le singole chiamate
    final futures = uncachedTexts.map((t) => translateText(t, langPair: langPair)).toList();
    final translatedUncached = await Future.wait(futures);
    for (int i = 0; i < translatedUncached.length; i++) {
      final origIndex = uncachedIndices[i];
      results[origIndex] = translatedUncached[i];
    }

    return results;
  }

  /// Metodo statico che traduce i nomi inglesi delle parti del corpo 
  /// forniti dall'API ExerciseDB in Italiano.
  String translateBodyPart(String? bodyPart) {
    if (bodyPart == null || bodyPart.trim().isEmpty) return "";
    switch (bodyPart.toLowerCase().trim()) {
      case "back":
        return "Schiena";
      case "cardio":
        return "Cardio";
      case "chest":
        return "Petto";
      case "lower arms":
        return "Avambracci";
      case "lower legs":
        return "Polpacci";
      case "neck":
        return "Collo";
      case "shoulders":
        return "Spalle";
      case "upper arms":
        return "Braccia";
      case "upper legs":
        return "Cosce";
      case "waist":
        return "Addome";
      default:
        return bodyPart[0].toUpperCase() + bodyPart.substring(1);
    }
  }

  /// Metodo statico che traduce i nomi inglesi dei muscoli specifici target 
  /// forniti dall'API ExerciseDB in Italiano.
  String translateTarget(String? target) {
    if (target == null || target.trim().isEmpty) return "";
    switch (target.toLowerCase().trim()) {
      case "abductors":
        return "Abduttori";
      case "abs":
        return "Addominali";
      case "adductors":
        return "Adduttori";
      case "biceps":
        return "Bicipiti";
      case "calves":
        return "Polpacci";
      case "cardiovascular system":
        return "Cardio";
      case "delts":
        return "Deltoidi";
      case "forearms":
        return "Avambracci";
      case "glutes":
        return "Glutei";
      case "hamstrings":
        return "Femorali";
      case "lats":
        return "Dorsali";
      case "levator scapulae":
        return "Elevatore della scapola";
      case "pectorals":
        return "Pettorali";
      case "quads":
        return "Quadricipiti";
      case "serratus anterior":
        return "Gran dentato";
      case "spine":
        return "Lombari";
      case "traps":
        return "Trapezi";
      case "triceps":
        return "Tricipiti";
      case "upper back":
        return "Dorsali Alti";
      default:
        return target[0].toUpperCase() + target.substring(1);
    }
  }
}
