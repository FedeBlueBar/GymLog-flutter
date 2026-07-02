// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gymlog_flutter/models/workout.dart';
import 'package:gymlog_flutter/models/exercise.dart';
import 'package:gymlog_flutter/notifiers/workout_notifier.dart';
import 'package:gymlog_flutter/notifiers/home_notifier.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkoutPlanDialog extends StatefulWidget {
  final Workout? workout;
  final String? clientUid;

  const WorkoutPlanDialog({super.key, this.workout, this.clientUid});

  @override
  State<WorkoutPlanDialog> createState() => _WorkoutPlanDialogState();
}

class _WorkoutPlanDialogState extends State<WorkoutPlanDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _selectedSplit;
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
    final notifier = Provider.of<WorkoutNotifier>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(
          widget.workout == null ? "Nuova Scheda" : "Modifica Scheda",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                if (_exercises.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Aggiungi almeno un esercizio!")),
                  );
                  return;
                }

                if (widget.clientUid != null) {
                  await notifier.saveWorkoutForClient(
                    widget.clientUid!,
                    _nameController.text.trim(),
                    _exercises,
                    _selectedSplit,
                  );
                } else {
                  await notifier.saveWorkout(
                    _nameController.text.trim(),
                    _exercises,
                    id: widget.workout?.id ?? "",
                    splitType: _selectedSplit,
                  );
                }

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
              TextFormField(
                controller: _nameController,
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  labelText: "Nome Allenamento",
                  labelStyle: const TextStyle(color: Colors.black),
                  filled: true,
                  fillColor: const Color(0xFFF6F5F8),
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
                      final result = await showDialog<Map<String, dynamic>>(
                        context: context,
                        builder: (ctx) => const ExerciseSearchDialog(),
                      );
                      if (result != null) {
                        _addExercise(result);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _exercises.isEmpty
                    ? const Center(
                          child: Text(
                            "Nessun esercizio aggiunto. Clicca su Aggiungi per iniziare.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                      )
                    : ReorderableListView.builder(
                        itemCount: _exercises.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) {
                              newIndex -= 1;
                            }
                            final item = _exercises.removeAt(oldIndex);
                            _exercises.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          final ex = _exercises[index];
                          return Card(
                            key: ValueKey(ex.id + index.toString()),
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
                                  const Icon(Icons.drag_handle, color: Colors.grey),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ex.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 6),
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

class ExerciseSearchDialog extends StatefulWidget {
  const ExerciseSearchDialog({super.key});

  @override
  State<ExerciseSearchDialog> createState() => _ExerciseSearchDialogState();
}

class _ExerciseSearchDialogState extends State<ExerciseSearchDialog> {
  final TextEditingController _queryController = TextEditingController();
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
    final notifier = Provider.of<WorkoutNotifier>(context);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Cerca Esercizio",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _queryController,
              cursorColor: Colors.black,
              decoration: InputDecoration(
                hintText: "Es: Panca piana, Squat, Petto...",
                prefixIcon: const Icon(Icons.search, color: Colors.black54),
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
              onChanged: (val) => _onSearchChanged(val, notifier),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: notifier.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.black))
                  : notifier.exerciseSearchResults.isEmpty
                      ? Center(
                          child: Text(
                            _queryController.text.trim().length < 2
                                ? "Digita almeno 2 caratteri per cercare"
                                : "Nessun risultato trovato",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: notifier.exerciseSearchResults.length,
                          itemBuilder: (ctx, idx) {
                            final item = notifier.exerciseSearchResults[idx];
                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.fitness_center, color: Colors.black, size: 20),
                              ),
                              title: Text(item['name'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("${item['bodyPart'] ?? ''} • ${item['target'] ?? ''}"),
                              onTap: () {
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
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: notifier.isLoading || exDetails == null
            ? const Center(child: CircularProgressIndicator(color: Colors.red))
            : Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          exDetails.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          notifier.clearExerciseDetails();
                          Navigator.pop(context);
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                    errorBuilder: (ctx, err, stack) =>
                                        const Center(child: Icon(Icons.broken_image, size: 60)),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildMuscleChip("Muscolo", exDetails.target ?? "N/D"),
                              _buildMuscleChip("Regione", exDetails.bodyPart ?? "N/D"),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Istruzioni per l'esecuzione:",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 8),
                          if (exDetails.instructions.isEmpty)
                            const Text("Nessuna istruzione disponibile.", style: TextStyle(color: Colors.grey))
                          else
                            ...exDetails.instructions.asMap().entries.map((entry) {
                              final index = entry.key + 1;
                              final instruction = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("$index. ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                                    Expanded(child: Text(instruction)),
                                  ],
                                ),
                              );
                            }),
                          const SizedBox(height: 20),
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

class SplitSettingsDialog extends StatefulWidget {
  const SplitSettingsDialog({super.key});

  @override
  State<SplitSettingsDialog> createState() => _SplitSettingsDialogState();
}

class _SplitSettingsDialogState extends State<SplitSettingsDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
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
    final notifier = Provider.of<WorkoutNotifier>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text("Pianificazione Split", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.black),
            onPressed: () async {
              final startMillis = _startDate?.millisecondsSinceEpoch ?? 0;
              final endMillis = _endDate?.millisecondsSinceEpoch ?? 0;
              await notifier.saveSplitPlan(startMillis, endMillis, _splitMap);
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
            const Text(
              "Periodo di Validità (Opzionale)",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: BorderSide(color: Colors.black.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
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
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: BorderSide(color: Colors.black.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
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
            const Text(
              "Programmazione Settimanale",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
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
                      Text(
                        _weekDays[index],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      DropdownButton<String>(
                        value: _splitMap[index] ?? "Rest",
                        underline: Container(),
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
