import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:gymlog_flutter/models/user_model.dart';
import 'package:gymlog_flutter/utils/constants.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _usersCol => _db.collection(Constants.usersCollection);
  CollectionReference get _usernamesCol => _db.collection(Constants.usernamesCollection);

  String _normalizeUsername(String username) {
    return username.trim().toLowerCase();
  }

  Future<void> _saveUsernameIndex(String uid, String username) async {
    final normalized = _normalizeUsername(username);
    if (normalized.isEmpty) return;

    await _usernamesCol.doc(normalized).set({
      'uid': uid,
      'username': username.trim(),
      'usernameLowercase': normalized,
    });
  }

  Future<void> _deleteUsernameIndex(String? username) async {
    final normalized = _normalizeUsername(username ?? '');
    if (normalized.isEmpty) return;
    await _usernamesCol.doc(normalized).delete();
  }

  Future<bool> userExists(String uid) async {
    try {
      final doc = await _usersCol.doc(uid).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _usersCol.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

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

  Future<void> saveUser(UserModel user) async {
    final cleanUsername = user.username.trim();

    final oldSnap = await _usersCol.doc(user.uid).get();
    String? oldUsername;
    if (oldSnap.exists) {
      final data = oldSnap.data() as Map<String, dynamic>?;
      oldUsername = data?['username'];
    }

    await _usersCol.doc(user.uid).set(user.toMap());

    if (oldUsername != null && oldUsername.toLowerCase() != cleanUsername.toLowerCase()) {
      await _deleteUsernameIndex(oldUsername);
    }

    if (cleanUsername.isNotEmpty) {
      await _saveUsernameIndex(user.uid, cleanUsername);
    }
  }

  Future<bool> isUsernameAvailable(String username, {String? excludeUid}) async {
    final normalized = _normalizeUsername(username);
    if (normalized.isEmpty) return false;

    try {
      final usernameDoc = await _usernamesCol.doc(normalized).get();
      if (!usernameDoc.exists) {
        return true;
      } else {
        final data = usernameDoc.data() as Map<String, dynamic>?;
        final ownerUid = data?['uid'] as String?;

        if (ownerUid == null || ownerUid.isEmpty) {
          return true;
        } else if (excludeUid != null && ownerUid == excludeUid) {
          return true;
        } else {
          final ownerUserDoc = await _usersCol.doc(ownerUid).get();
          return !ownerUserDoc.exists;
        }
      }
    } catch (e) {
      debugPrint("DEBUG: isUsernameAvailable exception: $e");
      if (e is FirebaseException && e.code == 'permission-denied') {
        debugPrint("DEBUG: Permission denied on unauthenticated username read check. Bypassing check since write rules will enforce uniqueness.");
        return true;
      }
      return false;
    }
  }

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
      await _usersCol.doc(uid).update(fields);
    }
  }

  Future<void> deleteUserDocument(String uid, String? username) async {
    await _usersCol.doc(uid).delete();
    if (username != null && username.isNotEmpty) {
      await _deleteUsernameIndex(username);
    }
  }
}

