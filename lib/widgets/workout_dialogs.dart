// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gymlog_flutter/models/workout.dart';
import 'package:gymlog_flutter/models/exercise.dart';
import 'package:gymlog_flutter/notifiers/workout_notifier.dart';
import 'package:gymlog_flutter/notifiers/home_notifier.dart';
import 'package:url_launcher/url_launcher.dart';

/// Finestra di dialogo per creare o modificare una scheda di allenamento.
/// Se [workout] è null, stiamo creando una nuova scheda.
/// Se [clientUid] è specificato, la scheda viene creata da un PT per quel cliente.
class WorkoutPlanDialog extends StatefulWidget {
  final Workout? workout;
  final String? clientUid;

  const WorkoutPlanDialog({super.key, this.workout, this.clientUid});

  @override
  State<WorkoutPlanDialog> createState() => _WorkoutPlanDialogState();
}

class _WorkoutPlanDialogState extends State<WorkoutPlanDialog> {
  final _formKey = GlobalKey<FormState>();
  
  /// Controller per il nome della scheda (es. "Petto-Bicipiti").
  late TextEditingController _nameController;
  
  /// Tipo di split selezionato (es. Push, Pull, Legs).
  late String _selectedSplit;
  
  /// Lista locale degli esercizi inclusi nella scheda.
  late List<Exercise> _exercises;

  final List<String> _splitTypes = [
    "Push",
    "Pull",
    "Legs",
    "Cardio",
    "Addome",
    "FullBody",
    "Rest",
    "Personalizzato"
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.workout?.name ?? "");
    _selectedSplit = widget.workout?.splitType ?? "Rest";
    if (!_splitTypes.contains(_selectedSplit)) {
      _selectedSplit = "Personalizzato";
    }
    _exercises = widget.workout?.exercises.map((e) => e.copyWith()).toList() ?? [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Aggiunge un nuovo esercizio (selezionato tramite la ricerca) alla scheda.
  void _addExercise(Map<String, dynamic> item) {
    setState(() {
      _exercises.add(Exercise(
        id: item['id'] ?? "",
        name: item['name'] ?? "",
        sets: "3",
        reps: "10",
        weight: "0 kg",
        gifUrl: item['gifUrl'],
        bodyPart: item['bodyPart'],
        target: item['target'],
        instructions: List<String>.from(item['instructions'] ?? []),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    // Recupera il notifier per poter salvare la scheda
    final notifier = Provider.of<WorkoutNotifier>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white, // Sfondo bianco per dare un look pulito
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0, // AppBar piatta
        // Titolo dinamico in base all'operazione (creazione o modifica)
        title: Text(
          widget.workout == null ? "Nuova Scheda" : "Modifica Scheda",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Pulsante di salvataggio
          TextButton(
            onPressed: () async {
              // Verifica la validità del form (in particolare il nome obbligatorio)
              if (_formKey.currentState!.validate()) {
                // Non permette di salvare se la scheda è vuota
                if (_exercises.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Aggiungi almeno un esercizio!")),
                  );
                  return;
                }

                // Salva o aggiorna la scheda tramite il Notifier
                if (widget.clientUid != null) {
                  // Salvataggio per conto di un cliente (modalità PT)
                  await notifier.saveWorkoutForClient(
                    widget.clientUid!,
                    _nameController.text.trim(),
                    _exercises,
                    _selectedSplit,
                  );
                } else {
                  // Salvataggio per il proprio profilo
                  await notifier.saveWorkout(
                    _nameController.text.trim(),
                    _exercises,
                    id: widget.workout?.id ?? "",
                    splitType: _selectedSplit,
                  );
                }

                // Dopo aver salvato, aggiorna i dati in Home e chiude il Dialog
                if (mounted) {
                  Provider.of<HomeNotifier>(context, listen: false).loadHomeData();
                  Navigator.pop(context);
                }
              }
            },
            child: const Text(
              "SALVA",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Campo di testo per il nome della scheda
              TextFormField(
                controller: _nameController,
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  labelText: "Nome Allenamento",
                  labelStyle: const TextStyle(color: Colors.black),
                  filled: true,
                  fillColor: const Color(0xFFF6F5F8), // Sfondo grigio tenue
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.black, width: 1.5),
                  ),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? "Inserisci il nome" : null,
              ),
              const SizedBox(height: 20),
              // Menu a tendina (Dropdown) per selezionare il tipo di split (Push, Pull, ecc.)
              DropdownButtonFormField<String>(
                initialValue: _selectedSplit,
                iconEnabledColor: Colors.black,
                dropdownColor: Colors.white,
                decoration: InputDecoration(
                  labelText: "Tipo di Split",
                  labelStyle: const TextStyle(color: Colors.black),
                  filled: true,
                  fillColor: const Color(0xFFF6F5F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black, width: 1.5),
                  ),
                ),
                // Mappa i tipi di split disponibili in un elenco di DropdownMenuItem
                items: _splitTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedSplit = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              // Intestazione per la lista di esercizi e pulsante di aggiunta
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Esercizi nella scheda",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Aggiungi"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      // Apre il dialog di ricerca degli esercizi
                      final result = await showDialog<Map<String, dynamic>>(
                        context: context,
                        builder: (ctx) => const ExerciseSearchDialog(),
                      );
                      // Se l'utente seleziona un esercizio, lo aggiunge alla lista
                      if (result != null) {
                        _addExercise(result);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Sezione scrollabile con la lista degli esercizi aggiunti
              Expanded(
                child: _exercises.isEmpty
                    ? const Center(
                          child: Text(
                            "Nessun esercizio aggiunto. Clicca su Aggiungi per iniziare.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                      )
                    // Utilizza una ReorderableListView per permettere all'utente di riordinare gli esercizi
                    : ReorderableListView.builder(
                        itemCount: _exercises.length,
                        // Callback per gestire il drag & drop
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            // Se spostiamo in basso, riduciamo l'indice di 1 per compensare lo spostamento interno della lista
                            if (newIndex > oldIndex) {
                              newIndex -= 1;
                            }
                            final item = _exercises.removeAt(oldIndex);
                            _exercises.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          final ex = _exercises[index];
                          // Ogni esercizio è mostrato all'interno di una Card
                          return Card(
                            key: ValueKey(ex.id + index.toString()), // Chiave univoca essenziale per ReorderableListView
                            color: const Color(0xFFF6F5F8),
                            elevation: 0,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  // Icona per suggerire all'utente che può trascinare la riga
                                  const Icon(Icons.drag_handle, color: Colors.grey),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Nome dell'esercizio
                                        Text(
                                          ex.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 6),
                                        // Riga di campi per configurare Serie, Ripetizioni, Peso
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                initialValue: ex.sets,
                                                keyboardType: TextInputType.text,
                                                decoration: const InputDecoration(
                                                  labelText: "Serie",
                                                  isDense: true,
                                                ),
                                                onChanged: (val) => ex.sets = val,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: TextFormField(
                                                initialValue: ex.reps,
                                                keyboardType: TextInputType.text,
                                                decoration: const InputDecoration(
                                                  labelText: "Ripet.",
                                                  isDense: true,
                                                ),
                                                onChanged: (val) => ex.reps = val,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: TextFormField(
                                                initialValue: ex.weight,
                                                keyboardType: TextInputType.text,
                                                decoration: const InputDecoration(
                                                  labelText: "Peso",
                                                  isDense: true,
                                                ),
                                                onChanged: (val) => ex.weight = val,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Bottone per rimuovere l'esercizio dalla scheda
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _exercises.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog per cercare gli esercizi usando [ExerciseApiService] tramite il [WorkoutNotifier].
class ExerciseSearchDialog extends StatefulWidget {
  const ExerciseSearchDialog({super.key});

  @override
  State<ExerciseSearchDialog> createState() => _ExerciseSearchDialogState();
}

class _ExerciseSearchDialogState extends State<ExerciseSearchDialog> {
  final TextEditingController _queryController = TextEditingController();
  
  /// Timer per implementare il "debounce": evita di fare richieste di rete ad ogni singola
  /// lettera digitata, aspettando 600ms che l'utente finisca di scrivere.
  Timer? _debounce;

  @override
  void dispose() {
    _queryController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query, WorkoutNotifier notifier) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      notifier.onSearchQueryChange(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ottiene il Notifier che gestisce lo stato di caricamento e i risultati della ricerca
    final notifier = Provider.of<WorkoutNotifier>(context);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        // Il dialog occupa al massimo il 70% dell'altezza dello schermo per non coprire la tastiera
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Intestazione con titolo e pulsante di chiusura
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Cerca Esercizio",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.pop(context), // Chiude il dialog senza restituire nulla
                )
              ],
            ),
            const SizedBox(height: 8),
            // Campo di testo per immettere la query di ricerca
            TextField(
              controller: _queryController,
              cursorColor: Colors.black,
              decoration: InputDecoration(
                hintText: "Es: Panca piana, Squat, Petto...",
                prefixIcon: const Icon(Icons.search, color: Colors.black54),
                filled: true,
                fillColor: const Color(0xFFF6F5F8), // Sfondo grigio tenue
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 1.5),
                ),
              ),
              // Ad ogni carattere digitato, chiama il metodo che implementa il debounce
              onChanged: (val) => _onSearchChanged(val, notifier),
            ),
            const SizedBox(height: 12),
            // Mostra il caricamento, un messaggio di feedback o la lista dei risultati
            Expanded(
              child: notifier.isLoading
                  // Se isLoading è true, mostra l'indicatore di caricamento circolare
                  ? const Center(child: CircularProgressIndicator(color: Colors.black))
                  : notifier.exerciseSearchResults.isEmpty
                      // Se la lista è vuota dopo o durante la ricerca, mostra un testo esplicativo
                      ? Center(
                          child: Text(
                            _queryController.text.trim().length < 2
                                ? "Digita almeno 2 caratteri per cercare"
                                : "Nessun risultato trovato",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        )
                      // Mostra la lista dei risultati tramite ListView
                      : ListView.builder(
                          itemCount: notifier.exerciseSearchResults.length,
                          itemBuilder: (ctx, idx) {
                            final item = notifier.exerciseSearchResults[idx];
                            return ListTile(
                              // Icona generica per l'esercizio nel cerchio grigio
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.fitness_center, color: Colors.black, size: 20),
                              ),
                              // Nome dell'esercizio in grassetto
                              title: Text(item['name'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
                              // Sottotitolo che mostra muscolo e regione target
                              subtitle: Text("${item['bodyPart'] ?? ''} • ${item['target'] ?? ''}"),
                              onTap: () {
                                // Al tap, chiude il dialog restituendo la mappa dei dati dell'esercizio selezionato
                                Navigator.pop(context, item);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Finestra di dialogo che mostra i dettagli di un esercizio,
/// inclusa l'immagine (GIF), le istruzioni e un eventuale bottone per il tutorial su YouTube.
class ExerciseDetailsDialog extends StatefulWidget {
  final Exercise exercise;

  const ExerciseDetailsDialog({super.key, required this.exercise});

  @override
  State<ExerciseDetailsDialog> createState() => _ExerciseDetailsDialogState();
}

class _ExerciseDetailsDialogState extends State<ExerciseDetailsDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WorkoutNotifier>(context, listen: false).loadExerciseDetails(widget.exercise);
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<WorkoutNotifier>(context);
    final exDetails = notifier.currentExerciseDetails;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        // Limita l'altezza del dialog all'80% dello schermo per la scrollabilità
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        // Se sta caricando o non ha i dati, mostra il loader
        child: notifier.isLoading || exDetails == null
            ? const Center(child: CircularProgressIndicator(color: Colors.red))
            : Column(
                children: [
                  // Riga superiore: Titolo e Pulsante di chiusura
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          exDetails.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 2, // Se il nome è lungo, va a capo fino a 2 linee
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          // Pulisce i dettagli salvati per liberare memoria prima di chiudere
                          notifier.clearExerciseDetails();
                          Navigator.pop(context);
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Contenuto scrollabile (Immagine, info, istruzioni, tutorial)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Mostra la GIF dell'esecuzione se disponibile
                          if (exDetails.gifUrl != null && exDetails.gifUrl!.isNotEmpty)
                            Center(
                              child: Container(
                                height: 180,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    exDetails.gifUrl!,
                                    fit: BoxFit.contain,
                                    // Gestione errore nel caricamento immagine
                                    errorBuilder: (ctx, err, stack) =>
                                        const Center(child: Icon(Icons.broken_image, size: 60)),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          // 2. Chip informativi per muscolo target e parte del corpo
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildMuscleChip("Muscolo", exDetails.target ?? "N/D"),
                              _buildMuscleChip("Regione", exDetails.bodyPart ?? "N/D"),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // 3. Istruzioni step-by-step
                          const Text(
                            "Istruzioni per l'esecuzione:",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 8),
                          if (exDetails.instructions.isEmpty)
                            const Text("Nessuna istruzione disponibile.", style: TextStyle(color: Colors.grey))
                          else
                            // Mappa ogni istruzione enumerandola
                            ...exDetails.instructions.asMap().entries.map((entry) {
                              final index = entry.key + 1;
                              final instruction = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Numero dello step in rosso e grassetto
                                    Text("$index. ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                    // Testo descrittivo espanso
                                    Expanded(child: Text(instruction)),
                                  ],
                                ),
                              );
                            }),
                          const SizedBox(height: 20),
                          // 4. Bottone per avviare l'app YouTube esterna (se c'è l'id del video)
                          if (exDetails.youtubeVideoId != null && exDetails.youtubeVideoId!.isNotEmpty)
                            Center(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                                label: const Text("Guarda Tutorial su YouTube", style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade700,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                onPressed: () async {
                                  // Crea un Uri valido per il video e prova a lanciarlo
                                  final url = Uri.parse("https://www.youtube.com/watch?v=${exDetails.youtubeVideoId}");
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url, mode: LaunchMode.externalApplication);
                                  }
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMuscleChip(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}

/// Finestra di dialogo per configurare il piano settimanale di allenamento (Split).
class SplitSettingsDialog extends StatefulWidget {
  const SplitSettingsDialog({super.key});

  @override
  State<SplitSettingsDialog> createState() => _SplitSettingsDialogState();
}

class _SplitSettingsDialogState extends State<SplitSettingsDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  
  /// Mappa che associa l'indice del giorno (0=Lunedì, 6=Domenica) al tipo di allenamento.
  final Map<int, String> _splitMap = {};

  final List<String> _splitOptions = [
    "Push",
    "Pull",
    "Legs",
    "Cardio",
    "Addome",
    "FullBody",
    "Rest"
  ];

  final List<String> _weekDays = [
    "Lunedì",
    "Martedì",
    "Mercoledì",
    "Giovedì",
    "Venerdì",
    "Sabato",
    "Domenica"
  ];

  @override
  void initState() {
    super.initState();
    final notifier = Provider.of<WorkoutNotifier>(context, listen: false);
    final plan = notifier.splitPlan;

    if (plan.startDate > 0) _startDate = DateTime.fromMillisecondsSinceEpoch(plan.startDate);
    if (plan.endDate > 0) _endDate = DateTime.fromMillisecondsSinceEpoch(plan.endDate);

    for (int i = 0; i < 7; i++) {
      _splitMap[i] = plan.split[i] ?? "Rest";
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Non impostata";
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    // Recupera il notifier per salvare il piano settimanale (SplitPlan)
    final notifier = Provider.of<WorkoutNotifier>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text("Pianificazione Split", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Bottone di conferma e salvataggio
          IconButton(
            icon: const Icon(Icons.check, color: Colors.black),
            onPressed: () async {
              // Converte le date in millisecondi (0 se null)
              final startMillis = _startDate?.millisecondsSinceEpoch ?? 0;
              final endMillis = _endDate?.millisecondsSinceEpoch ?? 0;
              // Salva il piano usando il Notifier
              await notifier.saveSplitPlan(startMillis, endMillis, _splitMap);
              // Se il widget è ancora montato, aggiorna i dati in Home e chiude la schermata
              if (mounted) {
                Provider.of<HomeNotifier>(context, listen: false).loadHomeData();
                Navigator.pop(context);
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sezione 1: Selezione del periodo di validità (Data di inizio e Data di fine)
            const Text(
              "Periodo di Validità (Opzionale)",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Bottone per selezionare la Data di Inizio
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: BorderSide(color: Colors.black.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      // Mostra il DatePicker nativo di Flutter personalizzato nei colori
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        builder: (ctx, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(primary: Colors.black),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setState(() => _startDate = picked);
                      }
                    },
                    child: Text("Inizio: ${_formatDate(_startDate)}", style: const TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                // Bottone per selezionare la Data di Fine
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: BorderSide(color: Colors.black.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      // Imposta come data iniziale la fine impostata in precedenza, oppure tra 7 giorni
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        builder: (ctx, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(primary: Colors.black),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setState(() => _endDate = picked);
                      }
                    },
                    child: Text("Fine: ${_formatDate(_endDate)}", style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Sezione 2: Selezione del tipo di allenamento (Split) per ogni giorno della settimana
            const Text(
              "Programmazione Settimanale",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            // Genera 7 contenitori, uno per ogni giorno della settimana
            ...List.generate(7, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F5F8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withOpacity(0.05), width: 0.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Nome del giorno (es. Lunedì)
                      Text(
                        _weekDays[index],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      // Menu a tendina per assegnare lo Split a quel giorno
                      DropdownButton<String>(
                        value: _splitMap[index] ?? "Rest",
                        underline: Container(), // Rimuove la linea di default sotto il Dropdown
                        iconEnabledColor: Colors.black,
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 16),
                        items: _splitOptions.map((opt) {
                          return DropdownMenuItem(value: opt, child: Text(opt));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _splitMap[index] = val;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
