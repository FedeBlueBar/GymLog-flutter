// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gymlog_flutter/notifiers/workout_notifier.dart';
import 'package:gymlog_flutter/notifiers/home_notifier.dart';
import 'package:gymlog_flutter/widgets/workout_dialogs.dart';
import 'package:gymlog_flutter/screens/active_workout_screen.dart';

// Schermata Principale della sezione "Allenamento".
// Mostra il calendario della settimana (Lunedì-Domenica) con il gruppo muscolare (Split) di ogni giorno.
// Permette di:
// 1. Vedere lo storico degli allenamenti passati.
// 2. Creare, modificare ed eliminare schede di allenamento personalizzate.
// 3. Avviare un allenamento odierno (creando una sessione attiva).
class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  int _selectedSuggestedIndex = 0;

  // Controlla se un log di allenamento (timestamp) appartiene a uno specifico giorno della settimana corrente
  bool _isLogOnDayOfWeek(int logTimestamp, int dayIndex, WorkoutNotifier notifier) {
    final logDate = DateTime.fromMillisecondsSinceEpoch(logTimestamp);
    final monday = notifier.getCurrentWeekMonday();
    final targetDate = monday.add(Duration(days: dayIndex));
    return logDate.year == targetDate.year &&
        logDate.month == targetDate.month &&
        logDate.day == targetDate.day;
  }

  // Verifica se il timestamp dell'allenamento corrisponde esattamente alla data passata in input
  bool _isLogOnSpecificDate(int logTimestamp, DateTime date) {
    final logDate = DateTime.fromMillisecondsSinceEpoch(logTimestamp);
    return logDate.year == date.year &&
        logDate.month == date.month &&
        logDate.day == date.day;
  }

  // Crea il widget (una Card) per mostrare i dettagli di un allenamento terminato (Log)
  // Include nome della scheda, orario di completamento e una lista di esercizi eseguiti (serie, ripetizioni, peso).
  Widget _buildWorkoutLogCard(dynamic log) {
    // Estrapola data e ora dal timestamp di completamento
    final date = DateTime.fromMillisecondsSinceEpoch(log.completedAt);
    final timeString = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.black.withOpacity(0.1), width: 0.5),
      ),
      color: Colors.white,
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Linea verde decorativa sul lato sinistro della card
            Container(
              width: 5,
              color: const Color(0xFF4CAF50),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Intestazione: Nome dell'allenamento e badge orario
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            log.workoutName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        // Badge "Completato ore HH:MM"
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check, color: Color(0xFF2E7D32), size: 12),
                              const SizedBox(width: 4),
                              Text(
                                "Completato ore $timeString",
                                style: const TextStyle(
                                  color: Color(0xFF2E7D32),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Generazione dinamica della lista degli esercizi completati
                    ...log.exercises.map((ex) {
                      // Parificazione dei dati: assicura che valori nulli o vuoti siano mostrati come "0"
                      final setsCount = int.tryParse(ex.sets.toString()) ?? 0;
                      final repsText = ex.reps.toString().isEmpty ? "0" : ex.reps;
                      final weightText = ex.weight.toString().isEmpty ? "0" : ex.weight;
                      
                      // Costruisce la stringa riassuntiva (es. "3 set • 10 rep @ 50 kg")
                      final detailsSummary = setsCount > 0 
                          ? "$setsCount set • $repsText rep @ $weightText kg" 
                          : "${ex.sets} set • ${ex.reps} rep @ ${ex.weight} kg";

                      // Container singolo per ogni esercizio
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F5F8).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black.withOpacity(0.05), width: 0.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 16),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ex.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    detailsSummary,
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Associa un colore di sfondo e del testo in base alla tipologia di split (es. Push, Pull, Legs)
  Map<String, Color> _getSplitColors(String splitType) {
    switch (splitType.toLowerCase().trim()) {
      case "push": return {"bg": const Color(0xFFFFF0E6), "text": const Color(0xFFFF6D00)}!;
      case "pull": return {"bg": const Color(0xFFE3F2FD), "text": const Color(0xFF1565C0)}!;
      case "legs": return {"bg": const Color(0xFFE8F5E9), "text": const Color(0xFF2E7D32)}!;
      case "cardio": return {"bg": const Color(0xFFFCE4EC), "text": const Color(0xFFC2185B)}!;
      case "full body":
      case "fullbody": return {"bg": const Color(0xFFF3E5F5), "text": const Color(0xFF6A1B9A)}!;
      case "upper body": return {"bg": const Color(0xFFE0F7FA), "text": const Color(0xFF00838F)}!;
      case "lower body": return {"bg": const Color(0xFFEFEBE9), "text": const Color(0xFF4E342E)}!;
      case "addome": return {"bg": const Color(0xFFFFFDE7), "text": const Color(0xFFF57F17)}!;
      default: return {"bg": const Color(0xFFF5F5F5), "text": const Color(0xFF616161)}!;
    }
  }

  // Converte un ammontare di secondi nel formato HH:MM:SS oppure MM:SS
  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    }
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  // Apre un calendario popup per cercare gli allenamenti svolti in una data specifica passata
  void _showDatePickerHistory(BuildContext context, WorkoutNotifier notifier) async {
    // Richiama il widget di sistema per la selezione della data
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      // Personalizza i colori del calendario
      builder: (ctx, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.black),
        ),
        child: child!,
      ),
    );

    // Se l'utente ha selezionato una data valida
    if (picked != null) {
      // Filtra i log in base alla data scelta
      final logsForDate = notifier.workoutLogs.where((log) {
        return _isLogOnSpecificDate(log.completedAt, picked);
      }).toList();

      final formattedDate = "${picked.day}/${picked.month}/${picked.year}";

      // Mostra una finestra di dialogo (AlertDialog) con i risultati trovati
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("Allenamenti del $formattedDate", style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            // Se non ci sono log, mostra un messaggio di avviso
            child: logsForDate.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Text(
                      "Nessun allenamento eseguito in questa data.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                // Se ci sono log, li mostra utilizzando il costruttore _buildWorkoutLogCard
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: logsForDate.length,
                    itemBuilder: (context, index) {
                      return _buildWorkoutLogCard(logsForDate[index]);
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Chiudi", style: TextStyle(color: Colors.black)),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<WorkoutNotifier>(context);
    
    // Giorno attualmente visualizzato nella UI (es. 0 = Lunedì, 1 = Martedì)
    final selectedDayIndex = notifier.currentDayIndex;
    final splitForDay = notifier.getSplitForDayIndex(selectedDayIndex);

    // Indice del giorno reale di oggi (0-6)
    final todayIndex = DateTime.now().weekday - 1;
    final isToday = selectedDayIndex == todayIndex;

    // Filtra lo storico degli allenamenti per mostrare solo quelli completati nel giorno selezionato
    final filteredLogs = notifier.workoutLogs.where((log) {
      return _isLogOnDayOfWeek(log.completedAt, selectedDayIndex, notifier);
    }).toList();

    // Filtra le schede suggerite o salvate che corrispondono al gruppo muscolare (Split) di oggi
    final suggestedWorkouts = notifier.workouts.where((w) {
      return w.splitType.toLowerCase() == splitForDay.toLowerCase();
    }).toList();

    final List<String> weekDaysNames = ["Lun", "Mar", "Mer", "Gio", "Ven", "Sab", "Dom"];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text("Allenamenti", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.black),
            tooltip: "Seleziona Data Storico",
            onPressed: () => _showDatePickerHistory(context, notifier),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            tooltip: "Impostazioni Split",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SplitSettingsDialog()),
              );
            },
          )
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // ---------------------------------------------------------
              // 1. HEADER SETTIMANA: Mostra i giorni (Lun-Dom) cliccabili
              // ---------------------------------------------------------
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                // Genera 7 widget cliccabili per i giorni della settimana
                child: Row(
                  children: List.generate(7, (index) {
                    final isSelected = selectedDayIndex == index;
                    final splitText = notifier.getSplitForDayIndex(index);
                    // Controlla se l'utente si è allenato in questo specifico giorno
                    final hasLog = notifier.workoutLogs.any(
                      (log) => _isLogOnDayOfWeek(log.completedAt, index, notifier),
                    );

                    // Formatta l'abbreviazione del tipo di allenamento da visualizzare sotto il giorno
                    String splitAbbrev = splitText;
                    switch (splitText.toLowerCase()) {
                      case "push":
                        splitAbbrev = "Push";
                        break;
                      case "pull":
                        splitAbbrev = "Pull";
                        break;
                      case "legs":
                        splitAbbrev = "Legs";
                        break;
                      case "cardio":
                        splitAbbrev = "Cardio";
                        break;
                      case "addome":
                        splitAbbrev = "Core";
                        break;
                      case "fullbody":
                        splitAbbrev = "Full";
                        break;
                      case "rest":
                        splitAbbrev = "Rest";
                        break;
                      default:
                        if (splitText.length > 5) {
                          splitAbbrev = splitText.substring(0, 5);
                        }
                    }

                    // Singolo pulsante (Card) per giorno della settimana
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Resetta l'indice suggerito quando si cambia giorno
                          setState(() {
                            _selectedSuggestedIndex = 0;
                          });
                          notifier.selectDay(index);
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          elevation: isSelected ? 4 : 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          // Colore invertito se il giorno è selezionato
                          color: isSelected ? Colors.black : const Color(0xFFF6F5F8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Nome abbreviato del giorno (es. Lun, Mar)
                                Text(
                                  weekDaysNames[index],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected ? Colors.white : Colors.grey.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                // Tipo di split previsto (es. Push, Rest)
                                Text(
                                  splitAbbrev,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isSelected ? Colors.white70 : Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                // Puntino verde che segnala la presenza di un allenamento terminato
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: hasLog ? Colors.green : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // ---------------------------------------------------------
              // 2. BANNER GIORNO: Mostra lo split del giorno (es. "Push")
              //    e permette di cambiarlo al volo (Menu a tendina)
              // ---------------------------------------------------------
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  color: const Color(0xFFF6F5F8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isToday ? "Allenamento di Oggi" : "Programmazione Giorno",
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Split: $splitForDay",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Pulsante con menu a tendina per cambiare lo split previsto del giorno
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.edit, color: Colors.black),
                              color: Colors.white,
                              surfaceTintColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onSelected: (val) async {
                                // Salva l'override giornaliero (es. cambia Push in Rest)
                                await notifier.saveDailyOverride(selectedDayIndex, val);
                                // Forza il ricaricamento nella HomeNotifier per allineare i dati
                                if (context.mounted) {
                                  Provider.of<HomeNotifier>(context, listen: false).loadHomeData();
                                }
                              },
                              // Genera le opzioni selezionabili nel menu
                              itemBuilder: (ctx) => [
                                "Push",
                                "Pull",
                                "Legs",
                                "Cardio",
                                "Addome",
                                "FullBody",
                                "Rest"
                              ].map((opt) {
                                return PopupMenuItem(
                                  value: opt, 
                                  child: Text(
                                    "Cambia in $opt",
                                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                                  )
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ---------------------------------------------------------
              // 3. CORPO DELLA SCHERMATA:
              //    - Se giorno PASSATO: solo storico
              //    - Se OGGI/FUTURO: scheda suggerita, elenco schede, storico di oggi
              // ---------------------------------------------------------
              Expanded(
                child: notifier.isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.red))
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        children: [
                          if (selectedDayIndex < todayIndex) ...[
                            // GIORNI PASSATI: Storico degli allenamenti svolti
                            const Text(
                              "Storico Allenamenti Svolti",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const Divider(),
                            if (filteredLogs.isEmpty)
                              Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                color: const Color(0xFFF6F5F8),
                                child: const SizedBox(
                                  height: 120,
                                  child: Center(
                                    child: Text(
                                      "Nessun allenamento eseguito in questo giorno.",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ),
                              )
                            else
                              ...filteredLogs.map((log) => _buildWorkoutLogCard(log)),
                          ] else ...[
                            // OGGI O FUTURO: Suggerito / Riposo e Schede disponibili
                            if (splitForDay.toLowerCase() == "rest")
                              // Mostra un banner speciale se lo split di oggi è "Rest"
                              Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                color: Colors.black.withOpacity(0.04),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black.withOpacity(0.15)),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.all(28),
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor: Colors.black.withOpacity(0.1),
                                        child: const Icon(Icons.bedtime, size: 28, color: Colors.black),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        "Giorno di Riposo",
                                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        "Il riposo è fondamentale per la crescita e il recupero muscolare. Goditi questa pausa e ricarica le energie!",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.black87, height: 1.4),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (suggestedWorkouts.isNotEmpty) ...[
                              // Mostra la scheda raccomandata per oggi in base allo split configurato (se presente)
                              Builder(builder: (context) {
                                // Evita errori fuori dai limiti se si ricarica la lista schede
                                if (_selectedSuggestedIndex >= suggestedWorkouts.length) {
                                  _selectedSuggestedIndex = 0;
                                }
                                final suggested = suggestedWorkouts[_selectedSuggestedIndex];

                                return Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  color: const Color(0xFFF6F5F8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Intestazione Card Suggerita
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: const Text(
                                                "SUGGERITO PER OGGI",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 9,
                                                  letterSpacing: 1.0,
                                                ),
                                              ),
                                            ),
                                            if (suggestedWorkouts.length > 1)
                                              Text(
                                                "${_selectedSuggestedIndex + 1} di ${suggestedWorkouts.length}",
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        // Genera i "chip" orizzontali per scorrere tra le varie schede suggerite, se ci sono più opzioni
                                        if (suggestedWorkouts.length > 1) ...[
                                          SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              children: List.generate(suggestedWorkouts.length, (idx) {
                                                final w = suggestedWorkouts[idx];
                                                final isSel = idx == _selectedSuggestedIndex;
                                                return Padding(
                                                  padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                                                  child: ChoiceChip(
                                                    label: Text(w.name, style: TextStyle(color: isSel ? Colors.white : Colors.black, fontSize: 11)),
                                                    selected: isSel,
                                                    selectedColor: Colors.black,
                                                    backgroundColor: Colors.black.withOpacity(0.08),
                                                    onSelected: (selected) {
                                                      if (selected) {
                                                        setState(() {
                                                          _selectedSuggestedIndex = idx;
                                                        });
                                                      }
                                                    },
                                                  ),
                                                );
                                              }),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                        ],
                                        // Dettagli scheda suggerita: Nome, Numero esercizi e Split type
                                        Text(
                                          suggested.name,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                "${suggested.exercises.length} esercizi",
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                "Split: ${suggested.splitType}",
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        const Divider(),
                                        const SizedBox(height: 8),
                                        // Elenco dei primi 3 esercizi della scheda
                                        ...suggested.exercises.take(3).map((ex) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                                            child: Row(
                                              children: [
                                                Icon(Icons.fitness_center, size: 16, color: Colors.black.withOpacity(0.8)),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    ex.name,
                                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                        // Mostra il conteggio degli esercizi rimanenti
                                        if (suggested.exercises.length > 3)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 24.0, top: 4.0),
                                            child: Text(
                                              "+ altri ${suggested.exercises.length - 3} esercizi",
                                              style: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 12),
                                            ),
                                          ),
                                        // Pulsante "AVVIA ALLENAMENTO" (Mostrato solo per il giorno corrente, non per i giorni futuri)
                                        if (isToday) ...[
                                          const SizedBox(height: 16),
                                          ElevatedButton.icon(
                                            icon: const Icon(Icons.play_arrow, color: Colors.white),
                                            label: const Text(
                                              "AVVIA ALLENAMENTO",
                                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.black,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                              minimumSize: const Size(double.infinity, 44),
                                              elevation: 0,
                                            ),
                                            onPressed: () {
                                              // Impedisce di avviare un nuovo allenamento se ne esiste già uno diverso in corso
                                              if (notifier.activeWorkout != null && notifier.activeWorkout?.id != suggested.id) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text("C'è già un allenamento in corso! Termina o annulla quello prima.")),
                                                );
                                                return;
                                              }
                                              // Avvia l'allenamento (creando ActiveWorkout state)
                                              if (notifier.activeWorkout?.id != suggested.id) {
                                                notifier.startWorkout(suggested);
                                              }
                                              // Redirige l'utente verso la schermata dell'allenamento attivo
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (ctx) => const ActiveWorkoutScreen()),
                                              );
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                            const SizedBox(height: 20),

                            const Divider(height: 32),
                            // Area con bottone per aggiungere nuove schede e lista schede salvate
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Modifica Scheda",
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                // Bottone per avviare il Dialog di creazione scheda (WorkoutPlanDialog vuoto)
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.add, color: Colors.white, size: 16),
                                  label: const Text("Crea Scheda", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (ctx) => const WorkoutPlanDialog()),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Stato Empty: Mostra un avviso se l'utente non ha alcuna scheda creata
                            if (notifier.workouts.isEmpty)
                              Card(
                                color: const Color(0xFFF6F5F8).withOpacity(0.5),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: const SizedBox(
                                  height: 120,
                                  child: Center(
                                    child: Text(
                                      "Nessuna scheda creata. Clicca su Crea Scheda per iniziare.",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ),
                              )
                            // Genera la lista delle schede salvate dall'utente o dal suo PT
                            else
                              ...notifier.workouts.map((w) {
                                // Determina se questa scheda è attualmente in corso di esecuzione
                                final isCurrentActive = notifier.activeWorkout?.id == w.id;
                                final tagColors = _getSplitColors(w.splitType);

                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(color: Colors.black.withOpacity(0.05), width: 1),
                                  ),
                                  elevation: 2,
                                  color: Colors.white,
                                  shadowColor: Colors.black.withOpacity(0.2),
                                  // Naviga alla modifica della scheda al tap dell'intera Card
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (ctx) => WorkoutPlanDialog(workout: w)),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  w.name,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    // Badge colorato per lo Split della scheda
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: tagColors["bg"],
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        w.splitType.toUpperCase(),
                                                        style: TextStyle(
                                                          color: tagColors["text"],
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w900,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      "${w.exercises.length} esercizi",
                                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                                                    ),
                                                  ],
                                                ),
                                                // Informazione opzionale: se la scheda è stata inviata da un PT (Comunità)
                                                if (w.senderName != null && w.senderName!.isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 6.0),
                                                    child: Text(
                                                      "Assegnata da PT: ${w.senderName}",
                                                      style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          // Azioni rapide per la scheda: Modifica, Elimina, Inizia/Riprendi
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Row(
                                                children: [
                                                  // Pulsante Modifica
                                                  IconButton(
                                                    icon: const Icon(Icons.edit, color: Colors.black87, size: 20),
                                                    style: IconButton.styleFrom(
                                                      backgroundColor: Colors.black.withOpacity(0.05),
                                                      shape: const CircleBorder(),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(builder: (ctx) => WorkoutPlanDialog(workout: w)),
                                                      );
                                                    },
                                                  ),
                                                  // Pulsante Elimina (con Alert di conferma)
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                                    style: IconButton.styleFrom(
                                                      backgroundColor: Colors.red.withOpacity(0.05),
                                                      shape: const CircleBorder(),
                                                    ),
                                                    onPressed: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (ctx) => AlertDialog(
                                                          title: const Text("Elimina Scheda"),
                                                          content: Text("Sei sicuro di voler eliminare la scheda '${w.name}'?"),
                                                          actions: [
                                                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annulla")),
                                                            TextButton(
                                                              onPressed: () {
                                                                notifier.deleteWorkout(w.id);
                                                                Navigator.pop(ctx);
                                                              },
                                                              child: const Text("Elimina", style: TextStyle(color: Colors.red)),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              // Pulsante INIZIA (colore nero) o RIPRENDI (colore verde, se è la scheda attiva in esecuzione)
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: isCurrentActive ? Colors.green : Colors.black,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                  elevation: 0,
                                                ),
                                                onPressed: () {
                                                  // Previene l'avvio se c'è un'altra scheda in corso
                                                  if (notifier.activeWorkout != null && !isCurrentActive) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text("C'è già un allenamento in corso! Termina o annulla quello prima.")),
                                                    );
                                                    return;
                                                  }
                                                  // Avvia il workout se non era già attivo
                                                  if (!isCurrentActive) {
                                                    notifier.startWorkout(w);
                                                  }
                                                  // Porta l'utente nella schermata "Workout in Corso"
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(builder: (ctx) => const ActiveWorkoutScreen()),
                                                  );
                                                },
                                                child: Text(
                                                  isCurrentActive ? "RIPRENDI" : "INIZIA",
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),

                            const SizedBox(height: 24),
                            const Text(
                              "Cronologia allenamenti oggi",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const Divider(),
                            if (filteredLogs.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24.0),
                                  child: Text("Nessun allenamento registrato per questa data.", style: TextStyle(color: Colors.grey)),
                                ),
                              )
                            else
                              ...filteredLogs.map((log) => _buildWorkoutLogCard(log)),
                          ],
                          const SizedBox(height: 80),
                        ],
                      ),
              )
            ],
          ),

          // ---------------------------------------------------------
          // 4. BANNER ALLENAMENTO IN CORSO (Sticky Bottom)
          //    Compare sopra alla lista se c'è un allenamento avviato e "minimizzato"
          // ---------------------------------------------------------
          if (notifier.activeWorkout != null && notifier.isMinimized)
            // Utilizzo di Positioned per ancorare il banner in basso (sticky) sopra la ListView
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Card(
                color: Colors.white,
                elevation: 1,
                // Bordo rosso semitrasparente per attirare l'attenzione sull'allenamento in corso
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.red.withOpacity(0.8), width: 1),
                ),
                // L'intera Card è cliccabile per massimizzare la schermata dell'allenamento
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    // Ripristina lo stato a "non minimizzato"
                    notifier.setWorkoutMinimized(false);
                    // Naviga nuovamente all'ActiveWorkoutScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => const ActiveWorkoutScreen()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              // Pallino rosso decorativo a sinistra (indicatore di registrazione/live)
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Testi descrittivi
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Titolo in maiuscoletto per indicare lo stato
                                    const Text(
                                      "ALLENAMENTO IN CORSO",
                                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.0),
                                    ),
                                    const SizedBox(height: 2),
                                    // Nome dell'allenamento attualmente attivo
                                    Text(
                                      notifier.activeWorkout!.name,
                                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Bottone "RIPRENDI" sulla destra (esegue la stessa azione dell'onTap della Card)
                        TextButton.icon(
                          style: TextButton.styleFrom(foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                          onPressed: () {
                            notifier.setWorkoutMinimized(false);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (ctx) => const ActiveWorkoutScreen()),
                            );
                          },
                          label: const Text("RIPRENDI", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                          icon: const Icon(Icons.play_arrow, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
