import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gymlog_flutter/notifiers/register_notifier.dart';
import 'package:gymlog_flutter/widgets/auth_text_field.dart';

class GoogleOnboardingScreen extends StatefulWidget {
  const GoogleOnboardingScreen({super.key});

  @override
  State<GoogleOnboardingScreen> createState() => _GoogleOnboardingScreenState();
}

class _GoogleOnboardingScreenState extends State<GoogleOnboardingScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _annoNascitaController = TextEditingController();
  final TextEditingController _altezzaController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();

  final List<String> _obiettivi = [
    "Perdita di peso",
    "Aumento massa",
    "Mantenimento",
    "Resistenza",
    "Forza"
  ];
  String? _selectedObiettivo;

  @override
  void dispose() {
    _usernameController.dispose();
    _annoNascitaController.dispose();
    _altezzaController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registerNotifier = Provider.of<RegisterNotifier>(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (registerNotifier.isRegisterSuccess) {
        registerNotifier.onRegisterHandled();
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
                  "Completa il profilo",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Ciao ${registerNotifier.nome}! Aggiungi gli ultimi dettagli.",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                AuthTextField(
                  label: "Username",
                  controller: _usernameController,
                ),
                const SizedBox(height: 12),
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
                ElevatedButton(
                  onPressed: registerNotifier.isLoading
                      ? null
                      : () {
                          registerNotifier.onUsernameChange(_usernameController.text);
                          registerNotifier.onAnnoDiNascitaChange(_annoNascitaController.text);
                          registerNotifier.onAltezzaChange(_altezzaController.text);
                          registerNotifier.onPesoChange(_pesoController.text);
                          registerNotifier.completeGoogleOnboarding();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
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
                      : const Text("Salva e continua"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
