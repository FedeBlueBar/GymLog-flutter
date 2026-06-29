import 'package:flutter/material.dart';

class WorkoutTodayCard extends StatelessWidget {
  final String? nomeWorkout;
  final bool hasActiveWorkout;
  final VoidCallback onAvviaAllenamento;

  const WorkoutTodayCard({
    super.key,
    required this.nomeWorkout,
    this.hasActiveWorkout = false,
    required this.onAvviaAllenamento,
  });

  @override
  Widget build(BuildContext context) {
    final hasWorkout = nomeWorkout != null;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: const Color(0xFFF6F5F8),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onAvviaAllenamento,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.fitness_center,
                    size: 24,
                    color: Colors.black,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Workout di oggi",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                nomeWorkout ?? "Nessun allenamento programmato",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: hasWorkout ? onAvviaAllenamento : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasActiveWorkout ? Colors.red : Colors.black,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color.fromRGBO(0, 0, 0, 0.5),
                  disabledForegroundColor: const Color.fromRGBO(255, 255, 255, 0.5),
                  elevation: 0,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow, size: 18),
                    const SizedBox(width: 4),
                    Text(hasActiveWorkout ? "Riprendi" : "Inizia"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
