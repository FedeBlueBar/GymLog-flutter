import 'dart:convert';
import 'package:http/http.dart' as http;

class ExerciseApiService {
  static const String _exerciseBaseUrl = "https://exercisedb.p.rapidapi.com";
  static const String _exerciseHost = "exercisedb.p.rapidapi.com";
  static const String _exerciseApiKey = "d29143552bmshe39daea3840bed8p1b8c6fjsn85c5623d3051";

  static const String _youtubeBaseUrl = "https://www.googleapis.com/youtube/v3";
  static const String _youtubeApiKey = "AIzaSyCMDIvY5DQKbI4a5lD2I1hzVmJImN-8zZ8";

  Future<List<Map<String, dynamic>>> getAllExercises({int limit = 50}) async {
    try {
      final url = Uri.parse("$_exerciseBaseUrl/exercises?limit=$limit");
      final response = await http.get(url, headers: {
        "X-RapidAPI-Key": _exerciseApiKey,
        "X-RapidAPI-Host": _exerciseHost,
      });

      if (response.statusCode == 200) {
        final List parsed = json.decode(response.body);
        return parsed.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<Map<String, dynamic>>> searchExercisesByName(String name, {int limit = 20}) async {
    try {
      final encodedName = Uri.encodeComponent(name.trim().toLowerCase());
      final url = Uri.parse("$_exerciseBaseUrl/exercises/name/$encodedName?limit=$limit");
      final response = await http.get(url, headers: {
        "X-RapidAPI-Key": _exerciseApiKey,
        "X-RapidAPI-Host": _exerciseHost,
      });

      if (response.statusCode == 200) {
        final List parsed = json.decode(response.body);
        return parsed.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>?> getExerciseById(String id) async {
    try {
      final url = Uri.parse("$_exerciseBaseUrl/exercises/exercise/$id");
      final response = await http.get(url, headers: {
        "X-RapidAPI-Key": _exerciseApiKey,
        "X-RapidAPI-Host": _exerciseHost,
      });

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      }
    } catch (_) {}
    return null;
  }

  Future<String?> searchYoutubeVideo(String exerciseName) async {
    try {
      final query = Uri.encodeComponent("$exerciseName exercise tutorial");
      final url = Uri.parse("$_youtubeBaseUrl/search?q=$query&part=snippet&maxResults=1&type=video&key=$_youtubeApiKey");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map parsed = json.decode(response.body);
        final items = parsed['items'] as List?;
        if (items != null && items.isNotEmpty) {
          final firstVideo = items.first as Map?;
          final videoIdMap = firstVideo?['id'] as Map?;
          return videoIdMap?['videoId']?.toString();
        }
      }
    } catch (_) {}
    return null;
  }
}
