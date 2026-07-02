class UserModel {
  final String uid;
  final String nome;
  final String cognome;
  final String username;
  final String email;
  final int annoDiNascita;
  final int altezza;
  final double peso;
  final String obiettivo;
  final bool isPersonalTrainer;
  final String? hasPersonalTrainer;
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
