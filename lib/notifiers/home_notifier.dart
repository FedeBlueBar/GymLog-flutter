import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:gymlog_flutter/models/daily_diet_stats.dart';
import 'package:gymlog_flutter/models/user_model.dart';
import 'package:gymlog_flutter/models/workout_log.dart';
import 'package:gymlog_flutter/models/workout.dart';
import 'package:gymlog_flutter/models/split_plan.dart';
import 'package:gymlog_flutter/services/auth_service.dart';
import 'package:gymlog_flutter/services/user_service.dart';

class HomeNotifier extends ChangeNotifier {
  final AuthService _authService;
  final UserService _userService;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  UserModel? _user;
  String _workoutOdierno = "Nessun allenamento";
  double? _pesoAttuale;
  int _kcalAssunte = 0;
  int _kcalObiettivo = 2000;
  int _streakGiorni = 0;
  int _workoutStreakGiorni = 0;
  int _dietStreakGiorni = 0;
  bool _isLoading = false;
  String? _errorMessage;

  HomeNotifier({
    required AuthService authService,
    required UserService userService,
  })  : _authService = authService,
        _userService = userService {
    loadHomeData();
  }

  UserModel? get user => _user;
  String? get workoutOdierno => _workoutOdierno;
  double? get pesoAttuale => _pesoAttuale;
  int get kcalAssunte => _kcalAssunte;
  int get kcalObiettivo => _kcalObiettivo;
  int get streakGiorni => _streakGiorni;
  int get workoutStreakGiorni => _workoutStreakGiorni;
  int get dietStreakGiorni => _dietStreakGiorni;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadHomeData() async {
    final uid = _authService.currentUserId;
    if (uid == null) {
      _isLoading = false;
      _errorMessage = "Nessuna sessione attiva";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _userService.getUser(uid);
      if (user != null) {
        _user = user;
        _pesoAttuale = user.peso > 0.0 ? user.peso : null;


        int kcalObiettivoVal = 2000;
        final userDoc = await _db.collection('CalendarDiet').doc(uid).get();
        if (userDoc.exists) {
          final data = userDoc.data();
          final goals = data?['diet_goals'] as Map<String, dynamic>?;
          if (goals != null) {
            final targetCal = goals['calories'] as num?;
            if (targetCal != null) {
              kcalObiettivoVal = targetCal.toInt();
            }
          }
        }


        int kcalAssunteVal = 0;
        final now = DateTime.now();
        final docId = "${now.year}_${now.month}_${now.day}";
        final dayDoc = await _db
            .collection('CalendarDiet')
            .doc(uid)
            .collection('days')
            .doc(docId)
            .get();

        if (dayDoc.exists) {
          final stats = DailyDietStats.fromMap(dayDoc.data()!);
          if (stats.totalCalories > 0) {
            kcalObiettivoVal = stats.totalCalories;
          }
          kcalAssunteVal = stats.consumedCalories;
        }


        int streakAttuale = 0;
        final logsSnapshot = await _db
            .collection('workout_logs')
            .where('userId', isEqualTo: uid)
            .get();
        final logs = logsSnapshot.docs
            .map((doc) => WorkoutLog.fromMap(doc.data(), doc.id))
            .toList();
        streakAttuale = _calculateWorkoutStreak(logs);


        int dietStreakAttuale = 0;
        final dietDaysSnapshot = await _db
            .collection('CalendarDiet')
            .doc(uid)
            .collection('days')
            .get();

        final List<DateTime> dietQualifiedDays = [];
        for (var doc in dietDaysSnapshot.docs) {
          final data = doc.data();
          final dietStats = DailyDietStats.fromMap(data);

          final distinctCategories = dietStats.foods
              .map((food) => food.category.trim().toLowerCase())
              .where((cat) => cat.isNotEmpty)
              .toSet();

          if (distinctCategories.length >= 3) {
            final parts = doc.id.split('_');
            if (parts.length == 3) {
              try {
                final year = int.parse(parts[0]);
                final month = int.parse(parts[1]);
                final day = int.parse(parts[2]);
                dietQualifiedDays.add(DateTime(year, month, day));
              } catch (_) {}
            }
          }
        }
        dietStreakAttuale = _calculateDietStreak(dietQualifiedDays);


        String workoutOdiernoVal = "Nessun allenamento";
        final splitPlanDoc = await _db.collection('user_splits').doc(uid).get();
        String targetSplit = "Rest";
        if (splitPlanDoc.exists) {
          final plan = SplitPlan.fromMap(splitPlanDoc.data()!);
          final todayIndex = DateTime.now().weekday - 1;
          final now = DateTime.now();
          final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

          if (plan.overrides.containsKey(dateStr)) {
            targetSplit = plan.overrides[dateStr] ?? "Rest";
          } else if (plan.startDate == 0 || plan.endDate == 0) {
            targetSplit = plan.split[todayIndex] ?? "Rest";
          } else {
            final targetMillis = DateTime(now.year, now.month, now.day, 12, 0).millisecondsSinceEpoch;
            if (targetMillis >= plan.startDate && targetMillis <= plan.endDate) {
              targetSplit = plan.split[todayIndex] ?? "Rest";
            } else {
              targetSplit = plan.split[todayIndex] ?? "Rest";
            }
          }
        } else {

          final defaultSplit = {
            0: "Push", 1: "Pull", 2: "Rest",
            3: "Legs", 4: "Cardio", 5: "Addome", 6: "Rest"
          };
          final todayIndex = DateTime.now().weekday - 1;
          targetSplit = defaultSplit[todayIndex] ?? "Rest";
        }

        if (targetSplit.toLowerCase() == "rest") {
          workoutOdiernoVal = "Giorno di Riposo";
        } else {
          workoutOdiernoVal = "Split: $targetSplit";
        }

        _workoutOdierno = workoutOdiernoVal;
        _kcalObiettivo = kcalObiettivoVal;
        _kcalAssunte = kcalAssunteVal;
        _streakGiorni = streakAttuale;
        _workoutStreakGiorni = streakAttuale;
        _dietStreakGiorni = dietStreakAttuale;
      } else {
        _errorMessage = "Errore caricamento profilo";
      }
    } catch (e) {
      debugPrint("Errore in loadHomeData: $e");
      _errorMessage = "Errore durante il caricamento dei dati: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  DateTime _epochMsToLocalDate(int epochMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochMs);
    return DateTime(dt.year, dt.month, dt.day);
  }

  int _calculateWorkoutStreak(List<WorkoutLog> workoutLogs) {
    final distinctDates = workoutLogs
        .map((log) => _epochMsToLocalDate(log.completedAt))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (distinctDates.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final firstDate = distinctDates.first;

    if (firstDate != today && firstDate != yesterday) {
      return 0;
    }

    int streak = 1;

    for (int index = 0; index < distinctDates.length - 1; index++) {
      final current = distinctDates[index];
      final next = distinctDates[index + 1];
      final diff = current.difference(next).inDays;

      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  int _calculateDietStreak(List<DateTime> qualifiedDays) {
    if (qualifiedDays.isEmpty) return 0;

    final sortedDays = qualifiedDays.toSet().toList()..sort((a, b) => b.compareTo(a));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final firstDate = sortedDays.first;

    if (firstDate != today && firstDate != yesterday) {
      return 0;
    }

    int streak = 1;

    for (int index = 0; index < sortedDays.length - 1; index++) {
      final current = sortedDays[index];
      final next = sortedDays[index + 1];
      final diff = current.difference(next).inDays;

      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }
}
