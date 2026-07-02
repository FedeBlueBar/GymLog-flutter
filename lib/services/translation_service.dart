import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  static const String _baseUrl = "https://api.mymemory.translated.net";
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

  String getLocalTranslation(String query) {
    final lowercaseQuery = query.toLowerCase().trim();
    if (_localFitnessTranslations.containsKey(lowercaseQuery)) {
      return _localFitnessTranslations[lowercaseQuery]!;
    }

    final words = lowercaseQuery.split(RegExp(r'\s+'));
    final translatedWords = words.map((word) {
      return _localFitnessTranslations[word] ?? word;
    });
    return translatedWords.join(" ");
  }

  String cleanEnglishQuery(String translated) {
    var cleaned = translated
        .replaceAll(RegExp(r'\(.*?\)'), "")
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), "")
        .trim()
        .toLowerCase();

    if (cleaned.endsWith("s") && !cleaned.endsWith("ss") && !cleaned.endsWith("us") && cleaned.length > 3) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    return cleaned;
  }

  Future<String> translateText(String text, {String langPair = "en|it"}) async {
    if (text.trim().isEmpty) return text;

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
        if (translatedText != null && translatedText.trim().isNotEmpty) {
          _cache[cacheKey] = translatedText;
          return translatedText;
        }
      }
    } catch (_) {}
    return text;
  }

  Future<List<String>> translateTexts(List<String> texts, {String langPair = "en|it"}) async {
    if (texts.isEmpty) return [];

    final results = List<String>.filled(texts.length, "");
    final uncachedIndices = <int>[];
    final uncachedTexts = <String>[];

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

    if (uncachedTexts.isEmpty) {
      return results;
    }

    try {
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
          if (translatedLines.length == uncachedTexts.length) {
            for (int i = 0; i < translatedLines.length; i++) {
              final origText = uncachedTexts[i];
              final cacheKey = "$langPair:$origText";
              _cache[cacheKey] = translatedLines[i];

              final origIndex = uncachedIndices[i];
              results[origIndex] = translatedLines[i];
            }
            return results;
          }
        }
      }
    } catch (_) {}

    final futures = uncachedTexts.map((t) => translateText(t, langPair: langPair)).toList();
    final translatedUncached = await Future.wait(futures);
    for (int i = 0; i < translatedUncached.length; i++) {
      final origIndex = uncachedIndices[i];
      results[origIndex] = translatedUncached[i];
    }

    return results;
  }

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
