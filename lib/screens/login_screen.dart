import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gymlog_flutter/notifiers/login_notifier.dart';
import 'package:gymlog_flutter/notifiers/register_notifier.dart';
import 'package:gymlog_flutter/widgets/auth_text_field.dart';
import 'package:gymlog_flutter/widgets/google_sign_in_button.dart';

// Schermata di Login.
// Permette all'utente di accedere al proprio account tramite Email/Password
// oppure utilizzando l'autenticazione rapida con Google.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller per leggere il testo inserito nei campi Email e Password
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // Stato per nascondere o mostrare la password (con l'icona dell'occhio)
  bool _passwordObscured = true;

  // Libera la memoria dei controller quando la schermata viene chiusa
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ottiene i Notifier per gestire il processo di Login e di eventuale Registrazione Google
    final loginNotifier = Provider.of<LoginNotifier>(context);
    final registerNotifier = Provider.of<RegisterNotifier>(context, listen: false);

    // Controlla ad ogni render se il login è andato a buon fine o se richiede completamento
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (loginNotifier.isLoginSuccess) {
        // Login completato: va alla Home
        loginNotifier.onLoginHandled();
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (loginNotifier.navigateToGoogleOnboarding) {
        // Login con Google parziale (nuovo utente): deve completare il profilo
        loginNotifier.onGoogleOnboardingHandled();
        Navigator.of(context).pushNamed('/google_onboarding');
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo dell'applicazione
                Image.asset(
                  'assets/images/icona_app_gym.png',
                  width: 200,
                  height: 200,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.fitness_center,
                    size: 100,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "GymLog",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Accedi al tuo account",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Campo di testo per l'Email
                AuthTextField(
                  label: "Email",
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                // Campo di testo per la Password con pulsante per nascondere/mostrare il testo
                AuthTextField(
                  label: "Password",
                  controller: _passwordController,
                  obscureText: _passwordObscured,
                  keyboardType: TextInputType.visiblePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordObscured ? Icons.visibility_off : Icons.visibility,
                      color: Colors.black54,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordObscured = !_passwordObscured;
                      });
                    },
                  ),
                ),
                // Selettore degli errori (mostra il testo rosso se c'è un problema di login)
                if (loginNotifier.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    loginNotifier.errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                // Bottone "Accedi" (disabilitato mentre sta caricando)
                ElevatedButton(
                  onPressed: loginNotifier.isLoading
                      ? null
                      : () {
                          // Invio dei dati inseriti verso il Notifier
                          loginNotifier.onEmailChange(_emailController.text);
                          loginNotifier.onPasswordChange(_passwordController.text);
                          loginNotifier.login();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: loginNotifier.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Accedi"),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.grey),
                const SizedBox(height: 16),
                // Pulsante personalizzato per accedere velocemente con l'account Google
                GoogleSignInButton(
                  isLoading: loginNotifier.isLoading,
                  onPressed: () {
                    loginNotifier.loginWithGoogle((uid, nome, cognome, email) {
                      // Se l'utente non esisteva ed è nuovo, salva i dati provvisori nel RegisterNotifier
                      registerNotifier.setGoogleUserData(uid, nome, cognome, email);
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Rimando alla pagina di Registrazione se l'utente non ha un account
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/register_step1');
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                  ),
                  child: const Text("Non hai un account? Registrati"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
