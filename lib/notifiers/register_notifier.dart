import 'package:flutter/foundation.dart';
import 'package:gymlog_flutter/models/user_model.dart';
import 'package:gymlog_flutter/services/auth_service.dart';
import 'package:gymlog_flutter/services/user_service.dart';

class RegisterNotifier extends ChangeNotifier {
  final AuthService _authService;
  final UserService _userService;

  RegisterNotifier({
    required AuthService authService,
    required UserService userService,
  })  : _authService = authService,
        _userService = userService;

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
  bool _isPersonalTrainer = false;

  bool _isGoogleFlow = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isRegisterSuccess = false;
  String? _pendingGoogleUid;

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

  void onNomeChange(String value) {
    _nome = value;
    _errorMessage = null;
    notifyListeners();
  }

  void onCognomeChange(String value) {
    _cognome = value;
    _errorMessage = null;
    notifyListeners();
  }

  void onEmailChange(String value) {
    _email = value;
    _errorMessage = null;
    notifyListeners();
  }

  void onUsernameChange(String value) {
    _username = value;
    _errorMessage = null;
    notifyListeners();
  }

  void onPasswordChange(String value) {
    _password = value;
    _errorMessage = null;
    notifyListeners();
  }

  void onConfermaPasswordChange(String value) {
    _confermaPassword = value;
    _errorMessage = null;
    notifyListeners();
  }

  void onObiettivoChange(String value) {
    _obiettivo = value;
    _errorMessage = null;
    notifyListeners();
  }

  void onAnnoDiNascitaChange(String value) {
    _annoDiNascita = value;
    _errorMessage = null;
    notifyListeners();
  }

  void onAltezzaChange(String value) {
    _altezza = value;
    _errorMessage = null;
    notifyListeners();
  }

  void onPesoChange(String value) {
    _peso = value;
    _errorMessage = null;
    notifyListeners();
  }

  void onIsPersonalTrainerChange(bool value) {
    _isPersonalTrainer = value;
    notifyListeners();
  }

  void setGoogleUserData(String uid, String nome, String cognome, String email) {
    _nome = nome;
    _cognome = cognome;
    _email = email;
    _isGoogleFlow = true;
    _errorMessage = null;
    _pendingGoogleUid = uid;
    notifyListeners();
  }

  void onRegisterHandled() {
    _isRegisterSuccess = false;
    notifyListeners();
  }

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
