import 'package:flutter/foundation.dart';

class WorkoutNotifier extends ChangeNotifier {
  String? _activeWorkout;
  bool _isMinimized = false;

  String? get activeWorkout => _activeWorkout;
  bool get isMinimized => _isMinimized;

  void startWorkout(String name) {
    _activeWorkout = name;
    _isMinimized = false;
    notifyListeners();
  }

  void endWorkout() {
    _activeWorkout = null;
    _isMinimized = false;
    notifyListeners();
  }

  void setWorkoutMinimized(bool minimized) {
    _isMinimized = minimized;
    notifyListeners();
  }
}
