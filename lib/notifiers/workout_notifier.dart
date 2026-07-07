// Questo file contiene il Notifier (Controller di stato) principale per l'allenamento.
// Gestisce l'intera logica legata alle schede (creazione, visualizzazione, modifica),
// al piano settimanale (Split Plan) e all'esecuzione vera e propria dell'allenamento
// (cronometro, spunta delle serie completate e salvataggio finale nel diario).

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:gymlog_flutter/models/workout.dart';
import 'package:gymlog_flutter/models/exercise.dart';
import 'package:gymlog_flutter/models/workout_log.dart';
import 'package:gymlog_flutter/models/split_plan.dart';
import 'package:gymlog_flutter/services/workout_service.dart';
import 'package:gymlog_flutter/services/exercise_api_service.dart';
import 'package:gymlog_flutter/services/translation_service.dart';

// Classe che estende ChangeNotifier per gestire e aggiornare la UI della sezione Allenamenti in tempo reale.
class WorkoutNotifier extends ChangeNotifier {
  // Dipendenze: servizi per interagire con il database, cercare esercizi tramite API esterne e tradurli
  final WorkoutService _workoutService = WorkoutService();
  final ExerciseApiService _exerciseApiService = ExerciseApiService();
  final TranslationService _translationService = TranslationService();

  String? _uid; // ID dell'utente attualmente connesso

  // Liste per mantenere in memoria le proprie schede e lo storico (diario)
  List<Workout> _workouts = [];
  List<Workout> get workouts => _workouts;

  List<WorkoutLog> _workoutLogs = [];
  List<WorkoutLog> get workoutLogs => _workoutLogs;

  // Stato per la gestione del Calendario/Programma Settimanale (Split Plan)
  SplitPlan _splitPlan = SplitPlan();
  SplitPlan get splitPlan => _splitPlan;

  int _currentDayIndex = 0;
  int get currentDayIndex => _currentDayIndex;

  Workout? _selectedWorkoutForToday;
  Workout? get selectedWorkoutForToday => _selectedWorkoutForToday;

  // Variabili generiche di stato per l'interfaccia (Caricamento, Errori, Successi)
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _saveSuccess = false;
  bool get saveSuccess => _saveSuccess;

  bool _workoutCompleted = false;
  bool get workoutCompleted => _workoutCompleted;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // =========================================================================
  // GESTIONE DELL'ALLENAMENTO IN CORSO (ACTIVE WORKOUT)
  // =========================================================================

  Workout? _activeWorkout; // La scheda che l'utente sta eseguendo in questo momento
  Workout? get activeWorkout => _activeWorkout;

  bool _isMinimized = false; // Se true, significa che l'utente ha ridotto a icona il player dell'allenamento per navigare altrove
  bool get isMinimized => _isMinimized;

  // Copia "viva" degli esercizi dell'allenamento in corso: qui l'utente può cambiare pesi e ripetizioni "al volo"
  List<Exercise> _activeExercises = [];
  List<Exercise> get activeExercises => _activeExercises;

  // Matrice per tenere traccia visivamente delle serie (sets) spuntate/completate dall'utente durante l'allenamento
  List<List<bool>> _activeSetCheckmarks = [];
  List<List<bool>> get activeSetCheckmarks => _activeSetCheckmarks;

  // Gestione del Cronometro dell'allenamento
  int _elapsedSeconds = 0;
  int get elapsedSeconds => _elapsedSeconds;
  Timer? _stopwatchTimer;

  List<Map<String, dynamic>> _exerciseSearchResults = [];
  List<Map<String, dynamic>> get exerciseSearchResults => _exerciseSearchResults;

  String _searchQuery = "";
  String get searchQuery => _searchQuery;

  Exercise? _currentExerciseDetails;
  Exercise? get currentExerciseDetails => _currentExerciseDetails;

  StreamSubscription? _workoutsSub;
  StreamSubscription? _logsSub;

  WorkoutNotifier() {
    _currentDayIndex = _getTodayIndex();
  }

  // Aggiorna l'ID utente attualmente attivo. Se valido, si iscrive agli aggiornamenti
  // del database (schede create, log passati, piano settimanale).
  void updateUserId(String? newUid) {
    if (_uid == newUid) return;
    _uid = newUid;

    _workoutsSub?.cancel();
    _logsSub?.cancel();
    _workouts = [];
    _workoutLogs = [];
    _splitPlan = SplitPlan();

    if (newUid != null && newUid.isNotEmpty) {
      _isLoading = true;
      notifyListeners();

      _workoutsSub = _workoutService.getWorkoutsRealtime(newUid).listen((list) async {
        final List<Workout> translatedList = [];
        for (var workout in list) {
          final names = workout.exercises.map((e) => e.name).toList();
          final translatedNames = await _translationService.translateTexts(names);
          final translatedExercises = workout.exercises.asMap().entries.map((entry) {
            final idx = entry.key;
            final ex = entry.value;
            final translatedName = translatedNames.length > idx ? translatedNames[idx] : ex.name;
            return ex.copyWith(name: translatedName);
          }).toList();
          translatedList.add(workout.copyWith(exercises: translatedExercises));
        }
        _workouts = translatedList;
        _isLoading = false;
        notifyListeners();
      }, onError: (err) {
        _errorMessage = err.toString();
        _isLoading = false;
        notifyListeners();
      });

      _logsSub = _workoutService.getWorkoutLogsRealtime(newUid).listen((list) async {
        final List<WorkoutLog> translatedList = [];
        for (var log in list) {
          final names = log.exercises.map((e) => e.name).toList();
          final translatedNames = await _translationService.translateTexts(names);
          final translatedExercises = log.exercises.asMap().entries.map((entry) {
            final idx = entry.key;
            final ex = entry.value;
            final translatedName = translatedNames.length > idx ? translatedNames[idx] : ex.name;
            return ex.copyWith(name: translatedName);
          }).toList();
          translatedList.add(WorkoutLog(
            id: log.id,
            userId: log.userId,
            workoutId: log.workoutId,
            workoutName: log.workoutName,
            completedAt: log.completedAt,
            exercises: translatedExercises,
          ));
        }
        _workoutLogs = translatedList;
        notifyListeners();
      });

      loadSplitPlan();
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Chiude gli stream del database e ferma il cronometro per non sprecare risorse quando la pagina non è in uso.
  @override
  void dispose() {
    _workoutsSub?.cancel();
    _logsSub?.cancel();
    _stopwatchTimer?.cancel();
    super.dispose();
  }

  // Restituisce l'indice del giorno odierno, calcolato da Lunedì (0) a Domenica (6).
  int _getTodayIndex() {
    return DateTime.now().weekday - 1;
  }

  // Cambia il giorno selezionato nel calendario della UI.
  void selectDay(int index) {
    _currentDayIndex = index;
    notifyListeners();
  }

  // Imposta provvisoriamente quale scheda eseguire oggi (scelta manuale dalla home).
  void selectWorkoutForToday(Workout? workout) {
    _selectedWorkoutForToday = workout;
    notifyListeners();
  }

  // Resetta il flag di successo, per evitare che un alert appaia due volte.
  void resetSaveSuccess() {
    _saveSuccess = false;
    notifyListeners();
  }

  // Resetta il flag che indica la fine di un allenamento, per far sparire il riepilogo.
  void resetWorkoutCompleted() {
    _workoutCompleted = false;
    notifyListeners();
  }

  // Cancella il testo di eventuali errori mostrati a schermo.
  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  // =========================================================================
  // GESTIONE CALENDARIO E PIANIFICAZIONE (SPLIT PLAN)
  // =========================================================================

  // Scarica da Firestore il programma settimanale dell'utente (es. Push, Pull, Legs, Rest)
  Future<void> loadSplitPlan() async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;
    try {
      _splitPlan = await _workoutService.getSplitPlan(uid);
      notifyListeners();
    } catch (e) {
      _errorMessage = "Errore caricamento split: $e";
      notifyListeners();
    }
  }

  // Salva l'intero piano settimanale e le sue date di validità sul database.
  Future<void> saveSplitPlan(int startDate, int endDate, Map<int, String> splitMap) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;
    _isLoading = true;
    notifyListeners();
    try {
      final updatedPlan = _splitPlan.copyWith(
        startDate: startDate,
        endDate: endDate,
        split: splitMap,
      );
      await _workoutService.saveSplitPlan(updatedPlan, uid);
      _splitPlan = updatedPlan;
    } catch (e) {
      _errorMessage = "Errore salvataggio split: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Aggiunge una "sovrascrittura" per un giorno specifico (es. oggi non faccio Push ma decido di fare Rest).
  Future<void> saveDailyOverride(int dayIndex, String newSplitType) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;
    _isLoading = true;
    notifyListeners();
    try {
      final dateStr = getDateStringForDayIndex(dayIndex);
      final updatedOverrides = Map<String, String>.from(_splitPlan.overrides);
      updatedOverrides[dateStr] = newSplitType;
      final updatedPlan = _splitPlan.copyWith(overrides: updatedOverrides);

      await _workoutService.saveSplitPlan(updatedPlan, uid);
      _splitPlan = updatedPlan;
    } catch (e) {
      _errorMessage = "Errore salvataggio override: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Rimuove una sovrascrittura giornaliera creata in precedenza, ripristinando lo standard.
  Future<void> clearDailyOverride(int dayIndex) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;
    _isLoading = true;
    notifyListeners();
    try {
      final dateStr = getDateStringForDayIndex(dayIndex);
      final updatedOverrides = Map<String, String>.from(_splitPlan.overrides);
      updatedOverrides.remove(dateStr);
      final updatedPlan = _splitPlan.copyWith(overrides: updatedOverrides);

      await _workoutService.saveSplitPlan(updatedPlan, uid);
      _splitPlan = updatedPlan;
    } catch (e) {
      _errorMessage = "Errore rimozione override: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Calcola e restituisce la data esatta corrispondente al Lunedì della settimana in corso.
  // Utile come punto di riferimento per calcolare i giorni successivi (Martedì, Mercoledì, ecc.).
  DateTime getCurrentWeekMonday() {
    final now = DateTime.now();
    final daysToSubtract = now.weekday - 1;
    return DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToSubtract));
  }

  // Calcola e formatta (in formato YYYY-MM-DD) la data corrispondente ad un certo indice
  // del giorno, partendo dall'inizio dell'attuale settimana.
  String getDateStringForDayIndex(int dayIndex) {
    final monday = getCurrentWeekMonday();
    final date = monday.add(Duration(days: dayIndex));
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Controlla quale Split (gruppo muscolare) è previsto per un dato giorno,
  // valutando prima se ci sono state "sovrascritture" manuali e poi leggendo il piano base.
  String getSplitForDayIndex(int dayIndex) {
    final plan = _splitPlan;
    final dateStr = getDateStringForDayIndex(dayIndex);

    if (plan.overrides.containsKey(dateStr)) {
      return plan.overrides[dateStr] ?? "Rest";
    }

    if (plan.startDate == 0 || plan.endDate == 0) {
      return plan.split[dayIndex] ?? "Rest";
    }

    final targetDate = getCurrentWeekMonday().add(Duration(days: dayIndex));
    final targetMillis = DateTime(targetDate.year, targetDate.month, targetDate.day, 12, 0).millisecondsSinceEpoch;

    final startNormalized = plan.startDate;
    final endNormalized = plan.endDate;

    if (targetMillis >= startNormalized && targetMillis <= endNormalized) {
      return plan.split[dayIndex] ?? "Rest";
    }

    return plan.split[dayIndex] ?? "Rest";
  }

  // Controlla semplicemente se per una determinata data c'è una modifica manuale ("override").
  bool hasDailyOverride(int dayIndex) {
    final dateStr = getDateStringForDayIndex(dayIndex);
    return _splitPlan.overrides.containsKey(dateStr);
  }

  // =========================================================================
  // RICERCA ED ESERCIZI (API)
  // =========================================================================

  // Interroga l'API esterna per cercare nuovi esercizi basandosi su un testo, per poi tradurli in italiano.
  Future<void> onSearchQueryChange(String query) async {
    _searchQuery = query;
    if (query.trim().length < 2) {
      _exerciseSearchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      var searchTerms = _translationService.getLocalTranslation(query);
      var results = await _exerciseApiService.searchExercisesByName(searchTerms);

      if (results.isEmpty && searchTerms != query) {
        results = await _exerciseApiService.searchExercisesByName(query);
      }

      if (results.isEmpty) {
        final translated = await _translationService.translateText(query, langPair: "it|en");
        final cleaned = _translationService.cleanEnglishQuery(translated);
        if (cleaned.isNotEmpty && cleaned != query && cleaned != searchTerms) {
          results = await _exerciseApiService.searchExercisesByName(cleaned);
        }
      }

      final namesToTranslate = results.map((item) => (item['name'] ?? "").toString()).toList();
      final translatedNames = await _translationService.translateTexts(namesToTranslate);

      _exerciseSearchResults = results.asMap().entries.map((entry) {
        final idx = entry.key;
        final item = entry.value;
        final name = translatedNames.length > idx ? translatedNames[idx] : (item['name'] ?? "");
        final bodyPart = _translationService.translateBodyPart(item['bodyPart']);
        final target = _translationService.translateTarget(item['target']);

        final finalId = item['exerciseId'] ?? item['id'] ?? "";
        final rawGif = item['gifUrl']?.toString();
        final gif = (rawGif != null && rawGif.isNotEmpty)
            ? rawGif.replaceAll("http://", "https://")
            : (finalId.isNotEmpty ? "https://static.exercisedb.dev/media/$finalId.gif" : null);

        return {
          ...item,
          'id': finalId,
          'name': name,
          'bodyPart': bodyPart,
          'target': target,
          'gifUrl': gif,
        };
      }).toList();
    } catch (_) {} finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Scarica le istruzioni dettagliate (equipment, descrizioni) per un singolo esercizio tramite l'API.
  Future<void> loadExerciseDetails(Exercise exercise) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (exercise.id.isNotEmpty) {
        final freshData = await _exerciseApiService.getExerciseById(exercise.id);
        if (freshData != null) {
          final englishName = freshData['name']?.toString() ?? "";
          
          final youtubeIdFut = _exerciseApiService.searchYoutubeVideo(englishName);
          final translatedNameFut = _translationService.translateText(englishName);
          final translatedBodyPartFut = _translationService.translateText(freshData['bodyPart']?.toString() ?? "");
          final translatedTargetFut = _translationService.translateText(freshData['target']?.toString() ?? "");

          final List<String> rawInstructions = [];
          if (freshData['instructions'] is List) {
            rawInstructions.addAll((freshData['instructions'] as List).map((e) => e.toString()));
          } else if (freshData['instructions'] != null) {
            rawInstructions.add(freshData['instructions'].toString());
          }
          final translatedInstructionsFut = _translationService.translateTexts(rawInstructions);

          final youtubeId = await youtubeIdFut;
          final translatedName = await translatedNameFut;
          final translatedBodyPart = await translatedBodyPartFut;
          final translatedTarget = await translatedTargetFut;
          final translatedInstructions = await translatedInstructionsFut;

          final rawGif = freshData['gifUrl']?.toString();
          final finalId = freshData['id']?.toString() ?? exercise.id;
          final gif = (rawGif != null && rawGif.isNotEmpty)
              ? rawGif.replaceAll("http://", "https://")
              : "https://static.exercisedb.dev/media/$finalId.gif";

          _currentExerciseDetails = exercise.copyWith(
            name: translatedName,
            gifUrl: gif,
            instructions: translatedInstructions,
            bodyPart: translatedBodyPart,
            target: translatedTarget,
            youtubeVideoId: youtubeId,
          );
        } else {
          _currentExerciseDetails = exercise;
        }
      } else {
        _currentExerciseDetails = exercise;
      }
    } catch (e) {
      _currentExerciseDetails = exercise;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Svuota i dettagli temporanei degli esercizi caricati in precedenza.
  void clearExerciseDetails() {
    _currentExerciseDetails = null;
    notifyListeners();
  }

  // =========================================================================
  // GESTIONE SCHEDE (WORKOUT)
  // =========================================================================

  // Salva o aggiorna una scheda creata dall'utente nel proprio database (Firestore).
  Future<void> saveWorkout(String name, List<Exercise> exercises, {String id = "", String splitType = "Rest"}) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;
    _isLoading = true;
    notifyListeners();
    try {
      final filtered = exercises.where((e) => e.name.trim().isNotEmpty).toList();
      final workout = Workout(
        id: id,
        userId: uid,
        name: name,
        exercises: filtered,
        splitType: splitType,
        createdAt: 0,
      );
      await _workoutService.saveWorkout(workout, uid);
      _saveSuccess = true;
    } catch (e) {
      _errorMessage = "Errore salvataggio scheda: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Permette ad un Personal Trainer di creare e salvare una scheda direttamente
  // sull'account di un proprio cliente (usando il suo UID).
  Future<void> saveWorkoutForClient(String clientUid, String name, List<Exercise> exercises, String splitType) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;
    _isLoading = true;
    notifyListeners();
    try {
      await _workoutService.saveWorkoutForClient(
        clientUid: clientUid,
        ptUid: uid,
        name: name,
        exercises: exercises,
        splitType: splitType,
      );
      _saveSuccess = true;
    } catch (e) {
      _errorMessage = "Errore salvataggio per cliente: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Elimina in modo irreversibile una scheda dal database utente.
  Future<void> deleteWorkout(String workoutId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _workoutService.deleteWorkout(workoutId);
    } catch (e) {
      _errorMessage = "Impossibile eliminare: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================================================================
  // ESECUZIONE DELL'ALLENAMENTO IN TEMPO REALE
  // =========================================================================

  // "Avvia" ufficialmente un allenamento. Prende gli esercizi previsti dalla scheda, prepara
  // la matrice delle spunte (falsa per tutte le serie all'inizio) e fa partire il cronometro.
  void startWorkout(Workout workout) {
    _activeWorkout = workout;
    _isMinimized = false;
    _elapsedSeconds = 0;
    _activeExercises = workout.exercises.map((e) => e.copyWith()).toList();

    _activeSetCheckmarks = _activeExercises.map((ex) {
      final setsCount = int.tryParse(ex.sets) ?? 1;
      return List<bool>.filled(setsCount, false);
    }).toList();

    _stopwatchTimer?.cancel();
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      notifyListeners();
    });

    notifyListeners();
  }

  // Interrompe bruscamente la sessione, pulendo le variabili e fermando il timer.
  void cancelWorkout() {
    _activeWorkout = null;
    _isMinimized = false;
    _activeExercises = [];
    _activeSetCheckmarks = [];
    _elapsedSeconds = 0;
    _stopwatchTimer?.cancel();
    notifyListeners();
  }

  // Riduce a icona o ingrandisce il player dell'allenamento in basso, permettendo di navigare.
  void setWorkoutMinimized(bool minimized) {
    _isMinimized = minimized;
    notifyListeners();
  }

  // Attiva/Disattiva la "V" (spunta verde) per dichiarare completata (o no) una specifica serie di un esercizio.
  void toggleSetCheckmark(int exerciseIndex, int setIndex) {
    if (exerciseIndex < _activeSetCheckmarks.length &&
        setIndex < _activeSetCheckmarks[exerciseIndex].length) {
      _activeSetCheckmarks[exerciseIndex][setIndex] = !_activeSetCheckmarks[exerciseIndex][setIndex];
      notifyListeners();
    }
  }

  // Permette all'utente di correggere le serie, ripetizioni o pesi di un esercizio "al volo"
  // mentre si allena (senza dover modificare permanentemente la scheda base).
  void updateActiveExerciseSetRepWeight(int exerciseIndex, {String? sets, String? reps, String? weight}) {
    if (exerciseIndex < _activeExercises.length) {
      final ex = _activeExercises[exerciseIndex];
      _activeExercises[exerciseIndex] = ex.copyWith(
        sets: sets ?? ex.sets,
        reps: reps ?? ex.reps,
        weight: weight ?? ex.weight,
      );

      if (sets != null) {
        final newSetsCount = int.tryParse(sets) ?? 1;
        final oldList = _activeSetCheckmarks[exerciseIndex];
        if (newSetsCount != oldList.length) {
          final newList = List<bool>.filled(newSetsCount, false);
          for (int i = 0; i < newList.length && i < oldList.length; i++) {
            newList[i] = oldList[i];
          }
          _activeSetCheckmarks[exerciseIndex] = newList;
        }
      }
      notifyListeners();
    }
  }

  // Dichiara concluso l'allenamento: valuta quanti esercizi sono stati effettivamente spuntati,
  // memorizza la durata totale e salva un nuovo "WorkoutLog" (Diario) su Firestore per le statistiche.
  Future<void> completeWorkout() async {
    final uid = _uid;
    final workout = _activeWorkout;
    if (uid == null || uid.isEmpty || workout == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final monday = getCurrentWeekMonday();
      final targetDate = monday.add(Duration(days: _currentDayIndex));
      final targetCal = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        now.hour,
        now.minute,
        now.second,
      );

      final log = WorkoutLog(
        id: "",
        userId: uid,
        workoutId: workout.id,
        workoutName: workout.name,
        completedAt: targetCal.millisecondsSinceEpoch,
        exercises: _activeExercises,
      );

      await _workoutService.saveWorkoutLog(log, uid);

      _activeWorkout = null;
      _isMinimized = false;
      _activeExercises = [];
      _activeSetCheckmarks = [];
      _elapsedSeconds = 0;
      _stopwatchTimer?.cancel();
      _workoutCompleted = true;
    } catch (e) {
      _errorMessage = "Salvataggio log fallito: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
