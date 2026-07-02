// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gymlog_flutter/notifiers/workout_notifier.dart';
import 'package:gymlog_flutter/widgets/workout_dialogs.dart';

class ActiveWorkoutScreen extends StatelessWidget {
  const ActiveWorkoutScreen({super.key});

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    }
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<WorkoutNotifier>(context);
    final workout = notifier.activeWorkout;

    if (workout == null) {
      return const Scaffold(
        body: Center(child: Text("Nessun allenamento attivo.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            notifier.setWorkoutMinimized(true);
            Navigator.pop(context);
          },
        ),
        title: Text(workout.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                "Timer: ${_formatDuration(notifier.elapsedSeconds)}",
                style: const TextStyle(fontSize: 14, color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: notifier.activeExercises.length,
              itemBuilder: (context, exIdx) {
                final ex = notifier.activeExercises[exIdx];
                final checkmarks = notifier.activeSetCheckmarks[exIdx];
                final targetSetsCount = int.tryParse(ex.sets) ?? 1;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: const Color(0xFFF6F5F8),
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => ExerciseDetailsDialog(exercise: ex),
                                  );
                                },
                                child: Text(
                                  ex.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.red,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              "Target: ${ex.sets}x${ex.reps} @ ${ex.weight}",
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        // Header row for inputs
                        const Row(
                          children: [
                            SizedBox(width: 40, child: Text("Set", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                            Expanded(child: Text("Ripetizioni", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                            SizedBox(width: 16),
                            Expanded(child: Text("Peso", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                            SizedBox(width: 60, child: Align(alignment: Alignment.centerRight, child: Text("Fatto", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(checkmarks.length, (setIdx) {
                          final isChecked = checkmarks[setIdx];

                          return Opacity(
                            opacity: isChecked ? 0.6 : 1.0,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 40,
                                    child: CircleAvatar(
                                      radius: 12,
                                      backgroundColor: isChecked ? Colors.green : Colors.grey.shade300,
                                      child: Text(
                                        "${setIdx + 1}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isChecked ? Colors.white : Colors.black87,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: SizedBox(
                                      height: 36,
                                      child: TextFormField(
                                        initialValue: ex.reps,
                                        keyboardType: TextInputType.text,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        ),
                                        onChanged: (val) {
                                          notifier.updateActiveExerciseSetRepWeight(exIdx, reps: val);
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: SizedBox(
                                      height: 36,
                                      child: TextFormField(
                                        initialValue: ex.weight,
                                        keyboardType: TextInputType.text,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        ),
                                        onChanged: (val) {
                                          notifier.updateActiveExerciseSetRepWeight(exIdx, weight: val);
                                        },
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 60,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Checkbox(
                                        value: isChecked,
                                        activeColor: Colors.green,
                                        onChanged: (val) {
                                          notifier.toggleSetCheckmark(exIdx, setIdx);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.add, size: 16, color: Colors.green),
                              label: const Text("Aggiungi Set", style: TextStyle(color: Colors.green, fontSize: 12)),
                              onPressed: () {
                                final newSetsCount = targetSetsCount + 1;
                                notifier.updateActiveExerciseSetRepWeight(exIdx, sets: newSetsCount.toString());
                              },
                            ),
                            if (checkmarks.length > 1)
                              TextButton.icon(
                                icon: const Icon(Icons.remove, size: 16, color: Colors.red),
                                label: const Text("Rimuovi Set", style: TextStyle(color: Colors.red, fontSize: 12)),
                                onPressed: () {
                                  final newSetsCount = checkmarks.length - 1;
                                  notifier.updateActiveExerciseSetRepWeight(exIdx, sets: newSetsCount.toString());
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Annulla Allenamento"),
                          content: const Text("Sei sicuro di voler annullare la sessione corrente? Tutti i progressi di oggi andranno persi."),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annulla")),
                            TextButton(
                              onPressed: () {
                                notifier.cancelWorkout();
                                Navigator.pop(ctx);
                                Navigator.pop(context);
                              },
                              child: const Text("Sì, annulla", style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text("Annulla", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      await notifier.completeWorkout();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Allenamento salvato con successo!"),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context);
                      }
                    },
                    child: const Text(
                      "Fine Allenamento",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
