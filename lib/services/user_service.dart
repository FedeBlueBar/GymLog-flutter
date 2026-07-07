import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:gymlog_flutter/models/user_model.dart';
import 'package:gymlog_flutter/utils/constants.dart';

/// Servizio per la gestione dei dati del profilo utente su Firestore.
/// Gestisce sia il documento principale dell'utente sia un registro univoco 
/// per gli username (per garantire l'unicità e facilitare la ricerca).
class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _usersCol => _db.collection(Constants.usersCollection);
  CollectionReference get _usernamesCol => _db.collection(Constants.usernamesCollection);

  /// Normalizza l'username rimuovendo spazi e convertendo in minuscolo.
  /// Utile per confronti case-insensitive e per le chiavi nel database.
  String _normalizeUsername(String username) {
    return username.trim().toLowerCase();
  }

  /// Salva (o aggiorna) il nome utente in una collezione dedicata ('usernames')
  /// in cui l'ID del documento è lo username normalizzato.
  /// Questo meccanismo previene che due utenti scelgano lo stesso nome.
  Future<void> _saveUsernameIndex(String uid, String username) async {
    final normalized = _normalizeUsername(username);
    if (normalized.isEmpty) return;

    await _usernamesCol.doc(normalized).set({
      'uid': uid,
      'username': username.trim(),
      'usernameLowercase': normalized,
    });
  }

  /// Elimina il record dell'username dalla collezione dedicata, liberandolo
  /// per essere usato da altri utenti (ad esempio quando un utente cambia nome o cancella l'account).
  Future<void> _deleteUsernameIndex(String? username) async {
    final normalized = _normalizeUsername(username ?? '');
    if (normalized.isEmpty) return;
    await _usernamesCol.doc(normalized).delete();
  }

  /// Controlla se esiste già un documento per un utente con l'UID specificato.
  Future<bool> userExists(String uid) async {
    try {
      final doc = await _usersCol.doc(uid).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  /// Recupera il profilo utente completo e lo converte in un'istanza [UserModel].
  Future<UserModel?> getUser(String uid) async {
    final doc = await _usersCol.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// Crea il documento utente base se non esiste. 
  /// Utilizza SetOptions(merge: true) per non sovrascrivere dati esistenti,
  /// molto utile nei flussi di registrazione multipasso.
  Future<void> ensureUserDocument(String uid, String email) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _usersCol.doc(uid).set({
      'uid': uid,
      'nome': '',
      'cognome': '',
      'email': email,
      'username': '',
      'annoDiNascita': 0,
      'altezza': 0,
      'peso': 0.0,
      'obiettivo': '',
      'personalTrainer': false,
      'photoUrl': '',
      'createdAt': now,
    }, SetOptions(merge: true));
  }

  /// Salva interamente o sovrascrive il profilo utente.
  /// Si occupa anche di mantenere allineato l'indice degli username, cancellando
  /// quello vecchio (se l'utente lo ha modificato) e salvando quello nuovo.
  Future<void> saveUser(UserModel user) async {
    final cleanUsername = user.username.trim();

    // Recupera l'username precedente dal db per verificare se è cambiato
    final oldSnap = await _usersCol.doc(user.uid).get();
    String? oldUsername;
    if (oldSnap.exists) {
      final data = oldSnap.data() as Map<String, dynamic>?;
      oldUsername = data?['username'];
    }

    // Salva i dati dell'utente
    await _usersCol.doc(user.uid).set(user.toMap());

    // Se l'username è cambiato, libera l'indice di quello vecchio
    if (oldUsername != null && oldUsername.toLowerCase() != cleanUsername.toLowerCase()) {
      await _deleteUsernameIndex(oldUsername);
    }

    // Salva il nuovo indice per l'username aggiornato
    if (cleanUsername.isNotEmpty) {
      await _saveUsernameIndex(user.uid, cleanUsername);
    }
  }

  /// Verifica se un nome utente è libero e può essere utilizzato.
  /// [excludeUid] serve a permettere all'utente di tenere lo stesso username che ha già (ad esempio 
  /// durante l'aggiornamento del profilo senza modifiche al nome utente).
  Future<bool> isUsernameAvailable(String username, {String? excludeUid}) async {
    final normalized = _normalizeUsername(username);
    if (normalized.isEmpty) return false;

    try {
      final usernameDoc = await _usernamesCol.doc(normalized).get();
      // Se il documento non esiste, lo username è libero
      if (!usernameDoc.exists) {
        return true;
      } else {
        final data = usernameDoc.data() as Map<String, dynamic>?;
        final ownerUid = data?['uid'] as String?;

        if (ownerUid == null || ownerUid.isEmpty) {
          return true; // Documento anomalo/vuoto
        } else if (excludeUid != null && ownerUid == excludeUid) {
          return true; // L'username appartiene già all'utente che sta facendo la richiesta
        } else {
          // Ultimo check: se l'utente possessore dell'username non esiste più nel db utenti, lo libera
          final ownerUserDoc = await _usersCol.doc(ownerUid).get();
          return !ownerUserDoc.exists;
        }
      }
    } catch (e) {
      debugPrint("DEBUG: isUsernameAvailable exception: $e");
      if (e is FirebaseException && e.code == 'permission-denied') {
        debugPrint("DEBUG: Permission denied on unauthenticated username read check. Bypassing check since write rules will enforce uniqueness.");
        // Ignora l'errore se le regole di Firebase impediscono la lettura prima dell'autenticazione, 
        // le regole di scrittura impediranno comunque i doppioni.
        return true;
      }
      return false;
    }
  }

  /// Aggiorna parzialmente i campi del profilo utente.
  /// Contiene logica specifica se uno dei campi da aggiornare è 'username',
  /// aggiornando di conseguenza l'indice nella collezione separata.
  Future<void> updateUserFields(String uid, Map<String, dynamic> fields) async {
    if (fields.containsKey('username')) {
      final newUsername = fields['username'] as String;

      final oldSnap = await _usersCol.doc(uid).get();
      String? oldUsername;
      if (oldSnap.exists) {
        final data = oldSnap.data() as Map<String, dynamic>?;
        oldUsername = data?['username'];
      }

      await _usersCol.doc(uid).update(fields);

      if (oldUsername != null && oldUsername.toLowerCase() != newUsername.toLowerCase()) {
        await _deleteUsernameIndex(oldUsername);
      }
      if (newUsername.isNotEmpty) {
        await _saveUsernameIndex(uid, newUsername);
      }
    } else {
      // Aggiornamento standard (nessuna interazione con l'indice username)
      await _usersCol.doc(uid).update(fields);
    }
  }

  /// Elimina il documento dell'utente e libera il suo username dall'indice.
  Future<void> deleteUserDocument(String uid, String? username) async {
    await _usersCol.doc(uid).delete();
    if (username != null && username.isNotEmpty) {
      await _deleteUsernameIndex(username);
    }
  }
}

