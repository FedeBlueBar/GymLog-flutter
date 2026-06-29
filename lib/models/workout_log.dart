class WorkoutLog {
  final String id;
  final String userId;
  final String workoutId;
  final String workoutName;
  final int completedAt;

  WorkoutLog({
    required this.id,
    required this.userId,
    required this.workoutId,
    required this.workoutName,
    required this.completedAt,
  });

  factory WorkoutLog.fromMap(Map<String, dynamic> map, String docId) {
    return WorkoutLog(
      id: map['id'] ?? docId,
      userId: map['userId'] ?? '',
      workoutId: map['workoutId'] ?? '',
      workoutName: map['workoutName'] ?? '',
      completedAt: (map['completedAt'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'workoutId': workoutId,
      'workoutName': workoutName,
      'completedAt': completedAt,
    };
  }
}
