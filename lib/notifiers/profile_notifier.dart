// Questo file contiene il Notifier (Controller di stato) per la gestione del Profilo Utente.
// Permette di leggere, modificare e salvare i dati personali dell'utente (come peso, altezza, obiettivi)
// comunicando con il database e aggiornando la schermata in tempo reale.

import 'package:flutter/foundation.dart';
import 'package:gymlog_flutter/models/user_model.dart';
import 'package:gymlog_flutter/services/auth_service.dart';
import 'package:gymlog_flutter/services/user_service.dart';

// Classe che estende ChangeNotifier per gestire lo stato della schermata Profilo.
class ProfileNotifier extends ChangeNotifier {
  // Dipendenze: servizi per leggere/scrivere i dati sul database e ottenere l'ID utente
  final AuthService _authService;
  final UserService _userService;

  // Stato interno: memorizza l'utente corrente e i flag per la UI
  UserModel? _user;           // Dati completi dell'utente loggato
  bool _isLoading = false;    // Indica se l'app sta scaricando il profilo (visualizza rotella di caricamento)
  bool _isSaving = false;     // Indica se l'app sta salvando una modifica
  String? _errorMessage;      // Messaggio di errore testuale da mostrare
  String? _successMessage;    // Messaggio di successo (es. "Profilo aggiornato")

  // Costruttore: carica in automatico i dati del profilo alla creazione
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

  // Metodo generico per aggiornare un singolo campo del profilo sul database.
  // Include un controllo speciale per lo 'username' per assicurarsi che non sia già utilizzato da altri.
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

  // Permette di cambiare la password (valido solo per login tramite Email/Password).
  // Richiede la password vecchia per ri-autenticare l'utente prima del cambio per motivi di sicurezza.
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
      await _authService.reauthenticate(oldPassword);
      await _authService.changePassword(newPassword);
      _successMessage = "Password aggiornata";
    } catch (e) {
      _errorMessage = "Errore cambio password. Verifica la password attuale.";
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // Invia un'email standard all'utente per il ripristino della password
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

  // Elimina in modo irreversibile l'account utente sia dal database Firestore sia da Firebase Auth.
  // Anche qui è richiesta la password per sicurezza.
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
      await _authService.reauthenticate(password);

      final username = _user?.username;
      await _userService.deleteUserDocument(uid, username);

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

  // Disconnette l'utente e lo rimanda alla schermata di accesso
  void logout() {
    _authService.logout();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }
}
