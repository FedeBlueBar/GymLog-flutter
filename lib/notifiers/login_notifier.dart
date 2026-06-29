import 'package:flutter/foundation.dart';
import 'package:gymlog_flutter/services/auth_service.dart';
import 'package:gymlog_flutter/services/user_service.dart';

class LoginNotifier extends ChangeNotifier {
  final AuthService _authService;
  final UserService _userService;

  LoginNotifier({
    required AuthService authService,
    required UserService userService,
  })  : _authService = authService,
        _userService = userService;

  String _email = '';
  String _password = '';
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLoginSuccess = false;
  bool _navigateToGoogleOnboarding = false;

  String get email => _email;
  String get password => _password;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoginSuccess => _isLoginSuccess;
  bool get navigateToGoogleOnboarding => _navigateToGoogleOnboarding;

  void onEmailChange(String value) {
    _email = value;
    _errorMessage = null;
    notifyListeners();
  }

  void onPasswordChange(String value) {
    _password = value;
    _errorMessage = null;
    notifyListeners();
  }

  void onLoginHandled() {
    _isLoginSuccess = false;
    notifyListeners();
  }

  void onGoogleOnboardingHandled() {
    _navigateToGoogleOnboarding = false;
    notifyListeners();
  }

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
