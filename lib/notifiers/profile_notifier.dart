import 'package:flutter/foundation.dart';
import 'package:gymlog_flutter/models/user_model.dart';
import 'package:gymlog_flutter/services/auth_service.dart';
import 'package:gymlog_flutter/services/user_service.dart';

class ProfileNotifier extends ChangeNotifier {
  final AuthService _authService;
  final UserService _userService;

  UserModel? _user;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  ProfileNotifier({
    required AuthService authService,
    required UserService userService,
  })  : _authService = authService,
        _userService = userService {
    loadProfile();
  }

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<void> loadProfile() async {
    final uid = _authService.currentUserId;
    if (uid == null) {
      _isLoading = false;
      _errorMessage = "Nessuna sessione attiva";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final profile = await _userService.getUser(uid);
      if (profile != null) {
        _user = profile;
      } else {
        _errorMessage = "Profilo non trovato";
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateField(String fieldKey, dynamic value) async {
    final uid = _authService.currentUserId;
    if (uid == null) {
      _errorMessage = "Sessione non valida";
      notifyListeners();
      return;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      if (fieldKey == 'username') {
        final cleanUsername = (value as String).trim();
        if (cleanUsername.isEmpty) {
          _isSaving = false;
          _errorMessage = "Username non valido";
          notifyListeners();
          return;
        }

        final available = await _userService.isUsernameAvailable(cleanUsername, excludeUid: uid);
        if (!available) {
          _isSaving = false;
          _errorMessage = "Username già in uso";
          notifyListeners();
          return;
        }
      }

      await _userService.updateUserFields(uid, {fieldKey: value});
      _successMessage = "Dati aggiornati";
      await loadProfile();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    if (newPassword.length < 6) {
      _errorMessage = "La nuova password deve avere almeno 6 caratteri";
      notifyListeners();
      return;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      // Reauthenticate first
      await _authService.reauthenticate(oldPassword);
      // Change password
      await _authService.changePassword(newPassword);
      _successMessage = "Password aggiornata";
    } catch (e) {
      _errorMessage = "Errore cambio password. Verifica la password attuale.";
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> sendResetPasswordEmail() async {
    final email = _user?.email;
    if (email == null || email.trim().isEmpty) {
      _errorMessage = "Email non disponibile";
      notifyListeners();
      return;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      _successMessage = "Email di reset inviata a $email";
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccount(String password, VoidCallback onSuccess) async {
    final uid = _authService.currentUserId;
    if (uid == null) {
      _errorMessage = "Sessione non valida";
      notifyListeners();
      return;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Reauthenticate first
      await _authService.reauthenticate(password);

      // 2. Delete Firestore record and username index
      final username = _user?.username;
      await _userService.deleteUserDocument(uid, username);

      // 3. Delete Firebase Auth account
      await _authService.deleteAccount();

      _successMessage = "Account eliminato";
      onSuccess();
    } catch (e) {
      _errorMessage = "Errore eliminazione. Verifica la password.";
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void logout() {
    _authService.logout();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }
}
