import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymlog_flutter/models/workout.dart';
import 'package:gymlog_flutter/models/exercise.dart';
import 'package:gymlog_flutter/models/workout_log.dart';
import 'package:gymlog_flutter/models/split_plan.dart';

class WorkoutService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _workoutsCol => _db.collection('workouts');
  CollectionReference get _workoutLogsCol => _db.collection('workout_logs');
  CollectionReference get _usersCol => _db.collection('users');

  Future<void> saveWorkout(Workout workout, String uid) async {
    final workoutId = workout.id.isEmpty ? _workoutsCol.doc().id : workout.id;
    final newWorkout = workout.copyWith(
      id: workoutId,
      userId: uid,
      createdAt: workout.createdAt == 0 ? DateTime.now().millisecondsSinceEpoch : workout.createdAt,
    );
    await _workoutsCol.doc(workoutId).set(newWorkout.toMap());
  }

  Future<void> sendWorkoutToFriend(Workout workout, String currentUid, String friendId) async {
    final senderDoc = await _usersCol.doc(currentUid).get();
    final senderName = (senderDoc.data() as Map?)?['nome']?.toString() ?? "Personal Trainer";
    final senderIsPT = (senderDoc.data() as Map?)?['personalTrainer'] ?? 
                       (senderDoc.data() as Map?)?['isPersonalTrainer'] ?? false;

    final receiverDoc = await _usersCol.doc(friendId).get();
    final receiverName = (receiverDoc.data() as Map?)?['nome']?.toString() ?? "Amico";

    final newWorkoutId = _workoutsCol.doc().id;
    final workoutCopy = workout.copyWith(
      id: newWorkoutId,
      userId: currentUid,
      assignedTo: friendId,
      senderId: currentUid,
      senderName: senderName,
      senderIsPersonalTrainer: senderIsPT,
      receiverName: receiverName,
      isReceived: true,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _workoutsCol.doc(newWorkoutId).set(workoutCopy.toMap());
  }

  Future<void> saveWorkoutForClient({
    required String clientUid,
    required String ptUid,
    required String name,
    required List<Exercise> exercises,
    required String splitType,
  }) async {
    final ptDoc = await _usersCol.doc(ptUid).get();
    final ptName = (ptDoc.data() as Map?)?['nome']?.toString() ?? "Personal Trainer";

    final clientDoc = await _usersCol.doc(clientUid).get();
    final clientName = (clientDoc.data() as Map?)?['nome']?.toString() ?? "Cliente";

    final newWorkoutId = _workoutsCol.doc().id;
    final workout = Workout(
      id: newWorkoutId,
      userId: ptUid,
      assignedTo: clientUid,
      name: name,
      exercises: exercises.where((e) => e.name.trim().isNotEmpty).toList(),
      splitType: splitType,
      senderId: ptUid,
      senderName: ptName,
      senderIsPersonalTrainer: true,
      receiverName: clientName,
      isReceived: true,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _workoutsCol.doc(newWorkoutId).set(workout.toMap());
  }

  Future<void> deleteWorkout(String workoutId) async {
    await _workoutsCol.doc(workoutId).delete();
  }

  Stream<List<Workout>> getWorkoutsRealtime(String uid) {
    final controller = StreamController<List<Workout>>();
    List<Workout> owned = [];
    List<Workout> assigned = [];

    void emitMerged() {
      final merged = (owned + assigned);
      final seenIds = <String>{};
      final unique = merged.where((w) => seenIds.add(w.id)).toList();
      unique.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!controller.isClosed) {
        controller.add(unique);
      }
    }

    final subOwned = _workoutsCol.where('userId', isEqualTo: uid).snapshots().listen(
      (snap) {
        owned = snap.docs
            .map((doc) => Workout.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        emitMerged();
      },
      onError: (err) {
        if (!controller.isClosed) controller.addError(err);
      },
    );

    final subAssigned = _workoutsCol.where('assignedTo', isEqualTo: uid).snapshots().listen(
      (snap) {
        assigned = snap.docs
            .map((doc) => Workout.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        emitMerged();
      },
      onError: (err) {
        if (!controller.isClosed) controller.addError(err);
      },
    );

    controller.onCancel = () {
      subOwned.cancel();
      subAssigned.cancel();
      controller.close();
    };

    return controller.stream;
  }

  Future<void> saveWorkoutLog(WorkoutLog log, String uid) async {
    final logId = _workoutLogsCol.doc().id;
    final newLog = WorkoutLog(
      id: logId,
      userId: uid,
      workoutId: log.workoutId,
      workoutName: log.workoutName,
      completedAt: log.completedAt,
      exercises: log.exercises,
    );
    await _workoutLogsCol.doc(logId).set(newLog.toMap());
  }

  Stream<List<WorkoutLog>> getWorkoutLogsRealtime(String uid) {
    return _workoutLogsCol.where('userId', isEqualTo: uid).snapshots().map((snap) {
      final logs = snap.docs
          .map((doc) => WorkoutLog.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      logs.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      return logs;
    });
  }

  Future<void> saveSplitPlan(SplitPlan plan, String uid) async {
    await _db.collection('user_splits').doc(uid).set(plan.toMap());
  }

  Future<SplitPlan> getSplitPlan(String uid) async {
    final doc = await _db.collection('user_splits').doc(uid).get();
    if (doc.exists) {
      return SplitPlan.fromMap(doc.data()!);
    } else {
      final defaultSplit = {
        0: "Push",
        1: "Pull",
        2: "Rest",
        3: "Legs",
        4: "Cardio",
        5: "Addome",
        6: "Rest"
      };
      return SplitPlan(startDate: 0, endDate: 0, split: defaultSplit, overrides: const {});
    }
  }
}
