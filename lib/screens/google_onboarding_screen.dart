import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gymlog_flutter/notifiers/register_notifier.dart';
import 'package:gymlog_flutter/widgets/auth_text_field.dart';

// Schermata dedicata a chi si registra o fa login tramite Google per la prima volta.
// Poiché Google fornisce solo Nome, Cognome e Email, questa schermata chiede all'utente
// di completare il suo profilo con i dati mancanti (Altezza, Peso, Obiettivo, ecc.).
class GoogleOnboardingScreen extends StatefulWidget {
  const GoogleOnboardingScreen({super.key});

  @override
  State<GoogleOnboardingScreen> createState() => _GoogleOnboardingScreenState();
}

class _GoogleOnboardingScreenState extends State<GoogleOnboardingScreen> {
  // Controller testuali per catturare l'input dell'utente nei vari campi
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _annoNascitaController = TextEditingController();
  final TextEditingController _altezzaController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();

  // Lista predefinita degli obiettivi fitness selezionabili tramite menu a tendina
  final List<String> _obiettivi = [
    "Perdita di peso",
    "Aumento massa",
    "Mantenimento",
    "Resistenza",
    "Forza"
  ];
  String? _selectedObiettivo;

  // Rilascia la memoria occupata dai controller quando la pagina viene chiusa
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
    // Ottiene il RegisterNotifier per gestire il completamento dei dati
    final registerNotifier = Provider.of<RegisterNotifier>(context);

    // Controlla dopo ogni rendering se il salvataggio è andato a buon fine
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (registerNotifier.isRegisterSuccess) {
        registerNotifier.onRegisterHandled();
        // Se tutto è ok, reindirizza direttamente alla home, cancellando la cronologia di navigazione
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      // La SafeArea garantisce che la UI non venga coperta da notch o barre di sistema
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
                // Campo per scegliere un nome utente univoco
                AuthTextField(
                  label: "Username",
                  controller: _usernameController,
                ),
                const SizedBox(height: 12),
                
                // Menu a tendina per selezionare l'obiettivo fitness
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
                // Campo per inserire l'anno di nascita (tastiera numerica)
                AuthTextField(
                  label: "Anno di nascita",
                  controller: _annoNascitaController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                
                // Campo per inserire l'altezza in centimetri
                AuthTextField(
                  label: "Altezza (cm)",
                  controller: _altezzaController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                
                // Campo per inserire il peso in chilogrammi (può contenere virgole/decimali)
                AuthTextField(
                  label: "Peso (kg)",
                  controller: _pesoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                
                // Switch per indicare se l'utente che si registra è un Personal Trainer
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
                // Visualizza eventuali messaggi di errore restituiti dal Notifier
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
                
                // Bottone di salvataggio dei dati e fine processo
                ElevatedButton(
                  onPressed: registerNotifier.isLoading
                      ? null
                      : () {
                          // Aggiorna le variabili nel Notifier e invia la richiesta di salvataggio a Firestore
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
