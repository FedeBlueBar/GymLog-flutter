import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gymlog_flutter/notifiers/register_notifier.dart';
import 'package:gymlog_flutter/widgets/auth_text_field.dart';

// Seconda e ultima fase della registrazione classica.
// Raccoglie dati di accesso (Username, Password) e parametri fisici (Anno, Altezza, Peso).
class RegisterStep2Screen extends StatefulWidget {
  const RegisterStep2Screen({super.key});

  @override
  State<RegisterStep2Screen> createState() => _RegisterStep2ScreenState();
}

class _RegisterStep2ScreenState extends State<RegisterStep2Screen> {
  // Controller testuali per le informazioni inserite in questo secondo step
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confermaPasswordController = TextEditingController();
  final TextEditingController _annoNascitaController = TextEditingController();
  final TextEditingController _altezzaController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();

  // Lista fissa degli obiettivi disponibili
  final List<String> _obiettivi = [
    "Perdita di peso",
    "Aumento massa",
    "Mantenimento",
    "Resistenza",
    "Forza"
  ];
  String? _selectedObiettivo;
  
  // Flag per nascondere o mostrare i campi password
  bool _passwordObscured = true;
  bool _confermaObscured = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confermaPasswordController.dispose();
    _annoNascitaController.dispose();
    _altezzaController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si aggancia allo stesso Notifier dello Step 1 per inviare in un'unica volta tutti i dati raccolti
    final registerNotifier = Provider.of<RegisterNotifier>(context);

    // Controlla dopo ogni rendering se la registrazione completa (su Firebase) è andata a buon fine
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (registerNotifier.isRegisterSuccess) {
        registerNotifier.onRegisterHandled();
        // Cestina la cronologia (login/registrazione) e va alla Home
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
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
                  "Step 2 di 2",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Campo Username
                AuthTextField(
                  label: "Username",
                  controller: _usernameController,
                ),
                const SizedBox(height: 12),
                // Campo Password (con occhio per mostrare/nascondere il testo)
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
                const SizedBox(height: 12),
                // Campo Conferma Password (deve coincidere col precedente)
                AuthTextField(
                  label: "Conferma password",
                  controller: _confermaPasswordController,
                  obscureText: _confermaObscured,
                  keyboardType: TextInputType.visiblePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _confermaObscured ? Icons.visibility_off : Icons.visibility,
                      color: Colors.black54,
                    ),
                    onPressed: () {
                      setState(() {
                        _confermaObscured = !_confermaObscured;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // Menu a tendina per l'obiettivo di allenamento
                DropdownButtonFormField<String>(
                  initialValue: _selectedObiettivo,
                  decoration: const InputDecoration(
                    labelText: "Obiettivo",
                    labelStyle: TextStyle(color: Colors.black54),
                    floatingLabelStyle: TextStyle(color: Colors.black),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 2.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 1.0),
                    ),
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: Colors.white,
                  items: _obiettivi.map((obiettivo) {
                    return DropdownMenuItem<String>(
                      value: obiettivo,
                      child: Text(
                        obiettivo,
                        style: const TextStyle(color: Colors.black),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedObiettivo = value;
                    });
                    if (value != null) {
                      registerNotifier.onObiettivoChange(value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                // Parametri fisici e anagrafici (numerici)
                AuthTextField(
                  label: "Anno di nascita",
                  controller: _annoNascitaController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                AuthTextField(
                  label: "Altezza (cm)",
                  controller: _altezzaController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                AuthTextField(
                  label: "Peso (kg)",
                  controller: _pesoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                
                // Switch per confermare se si è un PT
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        "Sono un Personal Trainer",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Switch(
                      value: registerNotifier.isPersonalTrainer,
                      onChanged: registerNotifier.onIsPersonalTrainerChange,
                      activeThumbColor: Colors.white,
                      activeTrackColor: Colors.black,
                      inactiveThumbColor: Colors.grey,
                      inactiveTrackColor: Colors.grey.shade300,
                    ),
                  ],
                ),
                
                // Visualizzazione degli errori in rosso
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
                
                // Bottoni d'azione: "Indietro" per correggere i dati, "Registrati" per completare
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text("Indietro"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: registerNotifier.isLoading
                            ? null
                            : () {
                                // Salvataggio dei dati nel Notifier prima dell'invio a Firestore
                                registerNotifier.onUsernameChange(_usernameController.text);
                                registerNotifier.onPasswordChange(_passwordController.text);
                                registerNotifier.onConfermaPasswordChange(_confermaPasswordController.text);
                                registerNotifier.onAnnoDiNascitaChange(_annoNascitaController.text);
                                registerNotifier.onAltezzaChange(_altezzaController.text);
                                registerNotifier.onPesoChange(_pesoController.text);
                                
                                // Chiamata al metodo di registrazione effettivo
                                registerNotifier.register();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: registerNotifier.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text("Registrati"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
