class Exercise {
  String id;
  String name;
  String sets;
  String reps;
  String weight;
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
