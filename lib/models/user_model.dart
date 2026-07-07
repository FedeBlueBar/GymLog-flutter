/// Questo file contiene il modello principale dell'Utente (UserModel).
/// Centralizza tutti i dati personali, fisici e i ruoli (es. se è un Personal Trainer)
/// legati all'utente attualmente autenticato o agli utenti esplorati nell'app.

// Modello che definisce l'anagrafica completa e lo stato di un utente.
class UserModel {
  // Identificativi e account
  final String uid;
  final String email;
  final String username;

  // Dati anagrafici di base
  final String nome;
  final String cognome;
  final int annoDiNascita;

  // Dati corporei e obiettivi
  final int altezza;
  final double peso;
  final String obiettivo;

  // Ruoli e stato (Community)
  final bool isPersonalTrainer;
  final String? hasPersonalTrainer; // Salva l'ID del Personal Trainer se l'utente è seguito da uno

  // Sistema e UI
  final String photoUrl;
  final int createdAt;

  UserModel({
    required this.uid,
    required this.nome,
    required this.cognome,
    required this.username,
    required this.email,
    required this.annoDiNascita,
    required this.altezza,
    required this.peso,
    required this.obiettivo,
    required this.isPersonalTrainer,
    this.hasPersonalTrainer,
    required this.photoUrl,
    required this.createdAt,
  });

  // Crea un'istanza partendo dai dati estratti dal database (in formato Mappa/JSON).
  // Richiede il [documentId] (l'ID del documento su Firestore) per assicurarsi che 
  //l'UID sia sempre valorizzato, anche se non esplicitamente salvato nei campi.
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: map['uid'] ?? documentId,
      nome: map['nome'] ?? '',
      cognome: map['cognome'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      annoDiNascita: (map['annoDiNascita'] as num?)?.toInt() ?? 0,
      altezza: (map['altezza'] as num?)?.toInt() ?? 0,
      peso: (map['peso'] as num?)?.toDouble() ?? 0.0,
      obiettivo: map['obiettivo'] ?? '',
      isPersonalTrainer: map['personalTrainer'] ?? map['isPersonalTrainer'] ?? false,
      hasPersonalTrainer: map['hasPersonalTrainer']?.toString(),
      photoUrl: map['photoUrl'] ?? '',
      createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
    );
  }

  // Converte l'oggetto in una Mappa (JSON) per permetterne il salvataggio o l'aggiornamento su Firestore.
  // Presta attenzione a far combaciare i nomi delle variabili con le chiavi storiche del database (es. `personalTrainer`).
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nome': nome,
      'cognome': cognome,
      'username': username,
      'email': email,
      'annoDiNascita': annoDiNascita,
      'altezza': altezza,
      'peso': peso,
      'obiettivo': obiettivo,
      'personalTrainer': isPersonalTrainer,
      'hasPersonalTrainer': hasPersonalTrainer,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
    };
  }
}
