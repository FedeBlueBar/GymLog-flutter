// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gymlog_flutter/notifiers/workout_notifier.dart';
import 'package:gymlog_flutter/notifiers/home_notifier.dart';
import 'package:gymlog_flutter/widgets/workout_dialogs.dart';
import 'package:gymlog_flutter/screens/active_workout_screen.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  int _selectedSuggestedIndex = 0;

  bool _isLogOnDayOfWeek(int logTimestamp, int dayIndex, WorkoutNotifier notifier) {
    final logDate = DateTime.fromMillisecondsSinceEpoch(logTimestamp);
    final monday = notifier.getCurrentWeekMonday();
    final targetDate = monday.add(Duration(days: dayIndex));
    return logDate.year == targetDate.year &&
        logDate.month == targetDate.month &&
        logDate.day == targetDate.day;
  }

  bool _isLogOnSpecificDate(int logTimestamp, DateTime date) {
    final logDate = DateTime.fromMillisecondsSinceEpoch(logTimestamp);
    return logDate.year == date.year &&
        logDate.month == date.month &&
        logDate.day == date.day;
  }

  Widget _buildWorkoutLogCard(dynamic log) {
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            log.workoutName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
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
                    ...log.exercises.map((ex) {
                      final setsCount = int.tryParse(ex.sets.toString()) ?? 0;
                      final repsText = ex.reps.toString().isEmpty ? "0" : ex.reps;
                      final weightText = ex.weight.toString().isEmpty ? "0" : ex.weight;
                      final detailsSummary = setsCount > 0 
                          ? "$setsCount set • $repsText rep @ $weightText kg" 
                          : "${ex.sets} set • ${ex.reps} rep @ ${ex.weight} kg";

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

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    }
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  void _showDatePickerHistory(BuildContext context, WorkoutNotifier notifier) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
      final logsForDate = notifier.workoutLogs.where((log) {
        return _isLogOnSpecificDate(log.completedAt, picked);
      }).toList();

      final formattedDate = "${picked.day}/${picked.month}/${picked.year}";

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text("Allenamenti del $formattedDate", style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: logsForDate.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Text(
                      "Nessun allenamento eseguito in questa data.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
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
    final selectedDayIndex = notifier.currentDayIndex;
    final splitForDay = notifier.getSplitForDayIndex(selectedDayIndex);

    final todayIndex = DateTime.now().weekday - 1; // 0..6
    final isToday = selectedDayIndex == todayIndex;

    // Filter historical logs completed on this day of the week
    final filteredLogs = notifier.workoutLogs.where((log) {
      return _isLogOnDayOfWeek(log.completedAt, selectedDayIndex, notifier);
    }).toList();

    // Workouts suggested for the current selected day split
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
              // WeekDays Selector Row - Equal width day columns (Row with Expandeds)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Row(
                  children: List.generate(7, (index) {
                    final isSelected = selectedDayIndex == index;
                    final splitText = notifier.getSplitForDayIndex(index);
                    final hasLog = notifier.workoutLogs.any(
                      (log) => _isLogOnDayOfWeek(log.completedAt, index, notifier),
                    );

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

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
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
                          color: isSelected ? Colors.black : const Color(0xFFF6F5F8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  weekDaysNames[index],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected ? Colors.white : Colors.grey.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
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

              // Split Info Box
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

                            PopupMenuButton<String>(
                              icon: const Icon(Icons.edit, color: Colors.black),
                              color: Colors.white,
                              surfaceTintColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onSelected: (val) async {
                                await notifier.saveDailyOverride(selectedDayIndex, val);
                                if (context.mounted) {
                                  Provider.of<HomeNotifier>(context, listen: false).loadHomeData();
                                }
                              },
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

              // Scrollable Lobby
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
                              // Renders SUGGERITO PER OGGI Card
                              Builder(builder: (context) {
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
                                        ...suggested.exercises.take(3).map((ex) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                                            child: Row(
                                              children: [
                                                Icon(Icons.fitness_center, size: 16, color: Colors.black.withOpacity(0.8)),
                                                const SizedBox(width: 8),
                                                Text(ex.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                                              ],
                                            ),
                                          );
                                        }),
                                        if (suggested.exercises.length > 3)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 24.0, top: 4.0),
                                            child: Text(
                                              "+ altri ${suggested.exercises.length - 3} esercizi",
                                              style: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 12),
                                            ),
                                          ),
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
                                              if (notifier.activeWorkout != null && notifier.activeWorkout?.id != suggested.id) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text("C'è già un allenamento in corso! Termina o annulla quello prima.")),
                                                );
                                                return;
                                              }
                                              if (notifier.activeWorkout?.id != suggested.id) {
                                                notifier.startWorkout(suggested);
                                              }
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

                            // Schede disponibili header
                            const Divider(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Modifica Scheda",
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
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
                            else
                              ...notifier.workouts.map((w) {
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
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Row(
                                                children: [
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
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: isCurrentActive ? Colors.green : Colors.black,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                  elevation: 0,
                                                ),
                                                onPressed: () {
                                                  if (notifier.activeWorkout != null && !isCurrentActive) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text("C'è già un allenamento in corso! Termina o annulla quello prima.")),
                                                    );
                                                    return;
                                                  }
                                                  if (!isCurrentActive) {
                                                    notifier.startWorkout(w);
                                                  }
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
                          const SizedBox(height: 80), // extra padding for floating active reminder card
                        ],
                      ),
              )
            ],
          ),

          // Floating Minimized Active Workout Reminder Card
          if (notifier.activeWorkout != null && notifier.isMinimized)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Card(
                color: Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.red.withOpacity(0.8), width: 1),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    notifier.setWorkoutMinimized(false);
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
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "ALLENAMENTO IN CORSO",
                                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.0),
                                    ),
                                    const SizedBox(height: 2),
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
