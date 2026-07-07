// Questo file contiene il modello dati per una singola Scheda di Allenamento (Workout).
// Oltre alla lista degli esercizi da svolgere, gestisce anche i dati di condivisione
// nel caso in cui la scheda sia stata assegnata da un Personal Trainer (PT) a un suo cliente.

import 'package:gymlog_flutter/models/exercise.dart';

// Modello che rappresenta una scheda di allenamento salvata.
class Workout {
  // Dati identificativi principali
  final String id;
  final String userId;        // ID dell'utente "proprietario" o creatore originario della scheda
  final String name;          // Nome assegnato alla scheda (es. "Gambe e Glutei")

  // Dati di assegnazione (sezione Community / PT)
  final String? assignedTo;   // Se presente, indica a quale utente (cliente) è stata assegnata la scheda dal PT
  final String? receiverName; // Nome di chi riceve la scheda (salvato per comodità di visualizzazione)
  final bool isReceived;      // true se la scheda è stata ricevuta da un PT, false se creata in autonomia

  // Dati del mittente (se la scheda è stata inviata da un PT o amico)
  final String? senderId;
  final String? senderName;
  final bool senderIsPersonalTrainer;

  // Contenuto della scheda e metadati
  final List<Exercise> exercises; // Lista in ordine degli esercizi da eseguire
  final int createdAt;            // Data di creazione in timestamp (millisecondi)
  final String splitType;         // Etichetta utile per smistare o organizzare le schede (es. "Push", "Pull", "Rest")

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

  // Crea un'istanza di Workout estrapolando i dati dal database (Mappa JSON/Firestore).
  // Esegue automaticamente il parsing della lista interna di esercizi per ricostruirli come oggetti 'Exercise'.
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

  // Converte la scheda di allenamento in una Mappa pronta per essere scritta sul database.
  // Si occupa di mappare ogni singolo Esercizio interno richiamando il rispettivo metodo toMap().
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

  // Crea una copia della scheda attuale sovrascrivendo solo i campi specificati.
  // Fondamentale in Flutter per aggiornare i dati in memoria (es. rinominare la scheda o scambiare l'ordine degli esercizi) in maniera pulita.
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
