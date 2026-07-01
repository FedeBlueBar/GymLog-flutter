import 'package:gymlog_flutter/models/exercise.dart';

class WorkoutLog {
  final String id;
  final String userId;
  final String workoutId;
  final String workoutName;
  final int completedAt;
  final List<Exercise> exercises;

  WorkoutLog({
    required this.id,
    required this.userId,
    required this.workoutId,
    required this.workoutName,
    required this.completedAt,
    this.exercises = const [],
  });

  factory WorkoutLog.fromMap(Map<String, dynamic> map, String docId) {
    final exercisesList = (map['exercises'] as List?)
            ?.map((e) => Exercise.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];

    return WorkoutLog(
      id: map['id'] ?? docId,
      userId: map['userId'] ?? '',
      workoutId: map['workoutId'] ?? '',
      workoutName: map['workoutName'] ?? '',
      completedAt: (map['completedAt'] as num?)?.toInt() ?? 0,
      exercises: exercisesList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'workoutId': workoutId,
      'workoutName': workoutName,
      'completedAt': completedAt,
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }
}
