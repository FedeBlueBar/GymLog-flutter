import 'package:gymlog_flutter/models/exercise.dart';

class Workout {
  final String id;
  final String userId;
  final String? assignedTo;
  final String name;
  final List<Exercise> exercises;
  final int createdAt;
  final String? senderId;
  final String? senderName;
  final bool senderIsPersonalTrainer;
  final String splitType;
  final String? receiverName;
  final bool isReceived;

  Workout({
    this.id = "",
    this.userId = "",
    this.assignedTo,
    this.name = "",
    this.exercises = const [],
    required this.createdAt,
    this.senderId,
    this.senderName,
    this.senderIsPersonalTrainer = false,
    this.splitType = "Rest",
    this.receiverName,
    this.isReceived = false,
  });

  factory Workout.fromMap(Map<String, dynamic> map, String docId) {
    final exercisesList = (map['exercises'] as List?)
            ?.map((e) => Exercise.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];

    return Workout(
      id: map['id'] ?? docId,
      userId: map['userId'] ?? "",
      assignedTo: map['assignedTo'],
      name: map['name'] ?? "",
      exercises: exercisesList,
      createdAt: map['createdAt'] is num ? (map['createdAt'] as num).toInt() : (map['createdAt']?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch),
      senderId: map['senderId'],
      senderName: map['senderName'],
      senderIsPersonalTrainer: map['senderIsPersonalTrainer'] ?? false,
      splitType: map['splitType'] ?? "Rest",
      receiverName: map['receiverName'],
      isReceived: map['isReceived'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'assignedTo': assignedTo,
      'name': name,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'createdAt': createdAt,
      'senderId': senderId,
      'senderName': senderName,
      'senderIsPersonalTrainer': senderIsPersonalTrainer,
      'splitType': splitType,
      'receiverName': receiverName,
      'isReceived': isReceived,
    };
  }

  Workout copyWith({
    String? id,
    String? userId,
    String? assignedTo,
    String? name,
    List<Exercise>? exercises,
    int? createdAt,
    String? senderId,
    String? senderName,
    bool? senderIsPersonalTrainer,
    String? splitType,
    String? receiverName,
    bool? isReceived,
  }) {
    return Workout(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      assignedTo: assignedTo ?? this.assignedTo,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderIsPersonalTrainer: senderIsPersonalTrainer ?? this.senderIsPersonalTrainer,
      splitType: splitType ?? this.splitType,
      receiverName: receiverName ?? this.receiverName,
      isReceived: isReceived ?? this.isReceived,
    );
  }
}
