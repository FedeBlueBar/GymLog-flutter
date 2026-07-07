// Questo file contiene il modello dati per lo Storico degli allenamenti (WorkoutLog).
// Serve a tenere traccia in modo permanente di un allenamento effettivamente completato
// da un utente in una determinata data.

import 'package:gymlog_flutter/models/exercise.dart';

// Modello che rappresenta una sessione di allenamento conclusa e salvata.
// Viene utilizzato per popolare il "diario" dell'utente e monitorare i progressi.
class WorkoutLog {
  // Dati identificativi e di collegamento
  final String id;
  final String userId;        // ID dell'utente che ha completato l'allenamento
  final String workoutId;     // ID della scheda originale (template) da cui deriva
  final String workoutName;   // Nome della scheda (salvato qui per comodità di lettura rapida)

  // Quando è stato completato (salvato in formato timestamp millisecondi)
  final int completedAt;

  // Lista esatta degli esercizi completati (con i pesi e le ripetizioni effettivamente eseguite in questa sessione)
  final List<Exercise> exercises;

  WorkoutLog({
    required this.id,
    required this.userId,
    required this.workoutId,
    required this.workoutName,
    required this.completedAt,
    this.exercises = const [],
  });

  // Crea un'istanza leggendo i dati dal database (Mappa JSON).
  // Si assicura di ricostruire in automatico anche la lista degli `Exercise` annidati.
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

  // Converte il log in una Mappa (JSON) per poterlo salvare definitivamente su Firestore.
  // Assicura che anche gli oggetti `Exercise` interni vengano correttamente convertiti a loro volta in mappe.
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
