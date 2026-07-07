import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gymlog_flutter/notifiers/register_notifier.dart';
import 'package:gymlog_flutter/widgets/auth_text_field.dart';

// Prima fase della registrazione classica (con email).
// Raccoglie i Dati Personali di base: Nome, Cognome ed Email.
class RegisterStep1Screen extends StatefulWidget {
  const RegisterStep1Screen({super.key});

  @override
  State<RegisterStep1Screen> createState() => _RegisterStep1ScreenState();
}

class _RegisterStep1ScreenState extends State<RegisterStep1Screen> {
  // Controller per catturare in tempo reale l'input inserito dall'utente nei campi
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _cognomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Quando l'utente esce dalla pagina, distrugge i controller per liberare RAM
  @override
  void dispose() {
    _nomeController.dispose();
    _cognomeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si aggancia al Notifier per conservare i dati man mano che si avanza nei vari "Step"
    final registerNotifier = Provider.of<RegisterNotifier>(context);

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
                const Text(
                  "Crea account",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Step 1 di 2",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 32),
                // Campo Nome
                AuthTextField(
                  label: "Nome",
                  controller: _nomeController,
                ),
                const SizedBox(height: 12),
                
                // Campo Cognome
                AuthTextField(
                  label: "Cognome",
                  controller: _cognomeController,
                ),
                const SizedBox(height: 12),
                
                // Campo Email
                AuthTextField(
                  label: "Email",
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                // Area dove compaiono eventuali errori (es. "Email non valida")
                if (registerNotifier.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    registerNotifier.errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                
                // Pulsante per passare allo Step 2 (Dati Sensibili e Account)
                ElevatedButton(
                  onPressed: () {
                    // 1. Salva i dati inseriti nel Notifier "centrale"
                    registerNotifier.onNomeChange(_nomeController.text);
                    registerNotifier.onCognomeChange(_cognomeController.text);
                    registerNotifier.onEmailChange(_emailController.text);
                    
                    // 2. Valida i dati (se la validazione passa, va alla pagina successiva)
                    if (registerNotifier.validateStep1()) {
                      Navigator.of(context).pushNamed('/register_step2');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text("Continua"),
                ),
                const SizedBox(height: 12),
                // Permette di tornare indietro alla schermata di Login se si ha già un account
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                  ),
                  child: const Text("Hai già un account? Accedi"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
