// Questo file contiene il Notifier (Controller di stato) per la gestione del Login.
// Gestisce l'autenticazione dell'utente (sia tramite email/password che tramite Google)
// e aggiorna la schermata in base agli stati di caricamento, ai successi o agli errori.

import 'package:flutter/foundation.dart';
import 'package:gymlog_flutter/services/auth_service.dart';
import 'package:gymlog_flutter/services/user_service.dart';

// Classe che estende ChangeNotifier per gestire i dati della schermata di login in tempo reale.
class LoginNotifier extends ChangeNotifier {
  // Dipendenze: servizi per l'autenticazione Firebase e la verifica dell'utente sul database
  final AuthService _authService;
  final UserService _userService;

  LoginNotifier({
    required AuthService authService,
    required UserService userService,
  })  : _authService = authService,
        _userService = userService;

  // Variabili di stato interne (Input dell'utente)
  String _email = '';
  String _password = '';
  // Stati per la gestione della UI (Caricamento ed eventuali messaggi di errore)
  bool _isLoading = false;
  String? _errorMessage;

  // Flag (segnali) per comandare la navigazione dalla UI
  bool _isLoginSuccess = false;
  bool _navigateToGoogleOnboarding = false; // Se true, significa che l'utente ha usato Google ma non ha ancora un profilo nel database

  String get email => _email;
  String get password => _password;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoginSuccess => _isLoginSuccess;
  bool get navigateToGoogleOnboarding => _navigateToGoogleOnboarding;

  // Aggiorna in tempo reale la variabile Email e rimuove eventuali errori passati non appena l'utente inizia a scrivere
  void onEmailChange(String value) {
    _email = value;
    _errorMessage = null;
    notifyListeners();
  }

  // Aggiorna in tempo reale la variabile Password e rimuove eventuali errori passati
  void onPasswordChange(String value) {
    _password = value;
    _errorMessage = null;
    notifyListeners();
  }

  // Resetta il flag di successo dopo che la UI lo ha letto ed ha effettuato la navigazione alla Home
  void onLoginHandled() {
    _isLoginSuccess = false;
    notifyListeners();
  }

  // Resetta il flag di completamento profilo Google dopo che la UI ha reindirizzato l'utente
  void onGoogleOnboardingHandled() {
    _navigateToGoogleOnboarding = false;
    notifyListeners();
  }

  // Avvia la procedura di Login tradizionale (con Email e Password) tramite Firebase Auth.
  Future<void> login() async {
    if (_email.trim().isEmpty || _password.isEmpty) {
      _errorMessage = "Email e password sono obbligatori";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.login(_email, _password);
      _isLoginSuccess = true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll(RegExp(r'\[.*\]\s*'), '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Avvia la procedura di Login tramite account Google.
  // Se l'utente non ha mai effettuato l'accesso prima d'ora (il suo UID non esiste sul database), 
  // avvia la navigazione verso il form di "Completamento Profilo" estrapolando i dati base (nome, email) da Google.
  Future<void> loginWithGoogle(Function(String uid, String nome, String cognome, String email) onSetGoogleData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _authService.signInWithGoogle();
      if (credential != null && credential.user != null) {
        final user = credential.user!;
        final uid = user.uid;
        final exists = await _userService.userExists(uid);

        if (exists) {
          _isLoginSuccess = true;
        } else {
          final displayName = user.displayName ?? '';
          final parts = displayName.split(' ');
          final nome = parts.isNotEmpty ? parts.first : '';
          final cognome = parts.length > 1 ? parts.sublist(1).join(' ') : '';
          final email = user.email ?? '';

          onSetGoogleData(uid, nome, cognome, email);
          _navigateToGoogleOnboarding = true;
        }
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll(RegExp(r'\[.*\]\s*'), '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
