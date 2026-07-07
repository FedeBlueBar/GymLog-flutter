// Questo file contiene il Notifier (Controller di stato) per la gestione della Registrazione.
// Si occupa di raccogliere e validare i dati inseriti dall'utente nel form, creare il suo account
// (sia standard che tramite Google) e inizializzare il suo profilo sul database.

import 'package:flutter/foundation.dart';
import 'package:gymlog_flutter/models/user_model.dart';
import 'package:gymlog_flutter/services/auth_service.dart';
import 'package:gymlog_flutter/services/user_service.dart';

// Classe che estende ChangeNotifier per gestire in tempo reale lo stato del form di registrazione.
class RegisterNotifier extends ChangeNotifier {
  // Dipendenze: servizi per gestire l'autenticazione Firebase e il database utenti
  final AuthService _authService;
  final UserService _userService;

  RegisterNotifier({
    required AuthService authService,
    required UserService userService,
  })  : _authService = authService,
        _userService = userService;

  // Variabili di stato interne (Tutti i campi testuali del modulo di registrazione)
  String _nome = '';
  String _cognome = '';
  String _email = '';
  String _username = '';
  String _password = '';
  String _confermaPassword = '';
  String _obiettivo = '';
  String _annoDiNascita = '';
  String _altezza = '';
  String _peso = '';
  bool _isPersonalTrainer = false; // Indica se l'utente si sta registrando come coach (PT)

  // Flag e stati per l'interfaccia utente (UI)
  bool _isGoogleFlow = false; // Se true, l'utente sta completando il profilo dopo aver effettuato il primo accesso con Google
  bool _isLoading = false;
  String? _errorMessage;
  bool _isRegisterSuccess = false;
  String? _pendingGoogleUid;  // L'UID fornito da Google, mantenuto in sospeso finché non si salva il profilo sul DB

  String get nome => _nome;
  String get cognome => _cognome;
  String get email => _email;
  String get username => _username;
  String get password => _password;
  String get confermaPassword => _confermaPassword;
  String get obiettivo => _obiettivo;
  String get annoDiNascita => _annoDiNascita;
  String get altezza => _altezza;
  String get peso => _peso;
  bool get isPersonalTrainer => _isPersonalTrainer;
  bool get isGoogleFlow => _isGoogleFlow;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isRegisterSuccess => _isRegisterSuccess;

  // ==========================================
  // METODI PER L'AGGIORNAMENTO IN TEMPO REALE
  // ==========================================
  // Questi metodi aggiornano le variabili interne ogni volta che l'utente digita
  // qualcosa nei campi di testo e azzerano eventuali messaggi di errore precedenti.
  void onNomeChange(String value) {
    _nome = value;
    _errorMessage = null;
    notifyListeners();
  }

  // Aggiorna la variabile interna del Cognome in tempo reale mentre l'utente digita
  void onCognomeChange(String value) {
    _cognome = value;
    _errorMessage = null;
    notifyListeners();
  }

  // Aggiorna la variabile interna dell'Email e azzera eventuali messaggi di errore precedenti
  void onEmailChange(String value) {
    _email = value;
    _errorMessage = null;
    notifyListeners();
  }

  // Aggiorna la variabile interna dell'Username
  void onUsernameChange(String value) {
    _username = value;
    _errorMessage = null;
    notifyListeners();
  }

  // Aggiorna la variabile interna della Password
  void onPasswordChange(String value) {
    _password = value;
    _errorMessage = null;
    notifyListeners();
  }

  // Aggiorna la variabile di sicurezza per verificare la corrispondenza della password
  void onConfermaPasswordChange(String value) {
    _confermaPassword = value;
    _errorMessage = null;
    notifyListeners();
  }

  // Aggiorna l'obiettivo scelto dall'utente (es. "Dimagrimento" o "Massa")
  void onObiettivoChange(String value) {
    _obiettivo = value;
    _errorMessage = null;
    notifyListeners();
  }

  // Aggiorna l'Anno di Nascita inserito dall'utente
  void onAnnoDiNascitaChange(String value) {
    _annoDiNascita = value;
    _errorMessage = null;
    notifyListeners();
  }

  // Aggiorna l'Altezza (in cm) inserita nel modulo
  void onAltezzaChange(String value) {
    _altezza = value;
    _errorMessage = null;
    notifyListeners();
  }

  // Aggiorna il Peso. Sostituirà eventuali virgole con punti al momento del salvataggio.
  void onPesoChange(String value) {
    _peso = value;
    _errorMessage = null;
    notifyListeners();
  }

  // Attiva o disattiva il flag che indica se l'utente si sta registrando come Personal Trainer
  void onIsPersonalTrainerChange(bool value) {
    _isPersonalTrainer = value;
    notifyListeners();
  }

  // ==========================================
  // LOGICA E AZIONI DI REGISTRAZIONE
  // ==========================================

  // Popola temporaneamente il form con i dati estratti dall'account Google.
  // Utile quando un utente si iscrive con Google ma deve ancora fornire altezza/peso.
  void setGoogleUserData(String uid, String nome, String cognome, String email) {
    _nome = nome;
    _cognome = cognome;
    _email = email;
    _isGoogleFlow = true;
    _errorMessage = null;
    _pendingGoogleUid = uid;
    notifyListeners();
  }

  // Resetta il flag di completamento dopo che la UI ha effettuato il cambio pagina
  void onRegisterHandled() {
    _isRegisterSuccess = false;
    notifyListeners();
  }

  // Controlla che il primo blocco del form (Dati Personali) sia compilato correttamente
  bool validateStep1() {
    if (_nome.trim().isEmpty || _cognome.trim().isEmpty) {
      _errorMessage = "Nome e cognome sono obbligatori";
      notifyListeners();
      return false;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (_email.trim().isEmpty || !emailRegex.hasMatch(_email.trim())) {
      _errorMessage = "Inserisci un'email valida";
      notifyListeners();
      return false;
    }

    _errorMessage = null;
    notifyListeners();
    return true;
  }

  // Esegue la registrazione tradizionale con Email e Password.
  // Crea prima l'utente su Firebase Auth e subito dopo salva i suoi dati nel database Firestore.
  Future<void> register() async {
    if (!_validateStep2()) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isAvailable = await _userService.isUsernameAvailable(_username);
      if (!isAvailable) {
        _errorMessage = "Username non disponibile";
        _isLoading = false;
        notifyListeners();
        return;
      }

      final credential = await _authService.register(_email, _password);
      final uid = credential.user!.uid;

      await _saveUserToFirestore(uid);
    } catch (e) {
      _errorMessage = e.toString().replaceAll(RegExp(r'\[.*\]\s*'), '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Completa la registrazione per un utente che si è autenticato con Google.
  // Poiché l'account Auth è già stato creato da Google, si limita a salvare i dati (inclusi quelli fisici appena inseriti) su Firestore.
  Future<void> completeGoogleOnboarding() async {
    final uid = _pendingGoogleUid;
    if (uid == null) {
      _errorMessage = "Sessione Google non valida, riprova";
      notifyListeners();
      return;
    }

    if (!_validateOnboarding()) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isAvailable = await _userService.isUsernameAvailable(_username, excludeUid: uid);
      if (!isAvailable) {
        _errorMessage = "Username non disponibile";
        _isLoading = false;
        notifyListeners();
        return;
      }

      await _saveUserToFirestore(uid);
    } catch (e) {
      _errorMessage = e.toString().replaceAll(RegExp(r'\[.*\]\s*'), '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Metodo interno di supporto che prende tutti i dati inseriti nel form,
  // crea un oggetto UserModel e lo salva nel database Firestore.
  Future<void> _saveUserToFirestore(String uid) async {
    try {
      await _userService.ensureUserDocument(uid, _email);

      final user = UserModel(
        uid: uid,
        nome: _nome.trim(),
        cognome: _cognome.trim(),
        username: _username.trim(),
        email: _email.trim(),
        annoDiNascita: int.tryParse(_annoDiNascita) ?? 0,
        altezza: int.tryParse(_altezza) ?? 0,
        peso: double.tryParse(_peso.replaceAll(',', '.')) ?? 0.0,
        obiettivo: _obiettivo,
        isPersonalTrainer: _isPersonalTrainer,
        hasPersonalTrainer: null,
        photoUrl: '',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await _userService.saveUser(user);

      _isRegisterSuccess = true;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll(RegExp(r'\[.*\]\s*'), '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Controlla che il secondo blocco del form (Credenziali/Account) sia valido,
  // verificando ad esempio la lunghezza della password e la sua corrispondenza.
  bool _validateStep2() {
    if (_username.trim().isEmpty) {
      _errorMessage = "Username obbligatorio";
      notifyListeners();
      return false;
    }
    if (_password.length < 6) {
      _errorMessage = "Password di almeno 6 caratteri";
      notifyListeners();
      return false;
    }
    if (_password != _confermaPassword) {
      _errorMessage = "Le password non coincidono";
      notifyListeners();
      return false;
    }
    if (_obiettivo.isEmpty) {
      _errorMessage = "Seleziona un obiettivo";
      notifyListeners();
      return false;
    }
    return true;
  }

  // Valida i campi essenziali per chi si registra tramite Google
  bool _validateOnboarding() {
    if (_username.trim().isEmpty) {
      _errorMessage = "Username obbligatorio";
      notifyListeners();
      return false;
    }
    if (_obiettivo.isEmpty) {
      _errorMessage = "Seleziona un obiettivo";
      notifyListeners();
      return false;
    }
    return true;
  }
}
