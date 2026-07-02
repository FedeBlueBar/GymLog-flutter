import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gymlog_flutter/notifiers/home_notifier.dart';
import 'package:gymlog_flutter/notifiers/workout_notifier.dart';
import 'package:gymlog_flutter/widgets/stat_card.dart';
import 'package:gymlog_flutter/widgets/tools_grid.dart';
import 'package:gymlog_flutter/widgets/workout_today_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeNotifier>().loadHomeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<HomeNotifier, WorkoutNotifier>(
      builder: (context, homeState, workoutState, child) {
        final user = homeState.user;
        final nomeUtente = (user?.nome.trim().isNotEmpty == true) ? user!.nome.trim() : "Atleta";
        final iniziale = nomeUtente[0].toUpperCase();

        return Scaffold(
          backgroundColor: const Color(0xFFEBEBEB),
          body: SafeArea(
            child: homeState.isLoading && user == null
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  )
                : RefreshIndicator(
                    onRefresh: () => homeState.loadHomeData(),
                    color: Colors.black,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "Bentornato/a, $nomeUtente",
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/profile'),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: const BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    iniziale,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          WorkoutTodayCard(
                            nomeWorkout: homeState.workoutOdierno,
                            hasActiveWorkout: workoutState.activeWorkout != null,
                            onAvviaAllenamento: () {
                              if (workoutState.activeWorkout != null) {
                                workoutState.setWorkoutMinimized(false);
                              }
                              Navigator.pushNamed(context, '/workout');
                            },
                          ),
                          const SizedBox(height: 16),

                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: StatCard(
                                    titolo: "Peso",
                                    valore: homeState.pesoAttuale != null
                                        ? "${homeState.pesoAttuale} kg"
                                        : "—",
                                    icona: Icons.monitor_weight_rounded,
                                    onClick: () => Navigator.pushNamed(context, '/progress'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: StatCard(
                                    titolo: "Calorie oggi",
                                    valore: "${homeState.kcalAssunte}",
                                    valoreObiettivo: "/ ${homeState.kcalObiettivo}",
                                    progress: homeState.kcalObiettivo > 0
                                        ? (homeState.kcalAssunte / homeState.kcalObiettivo)
                                            .clamp(0.0, 1.0)
                                        : 0.0,
                                    icona: Icons.restaurant_rounded,
                                    onClick: () => Navigator.pushNamed(context, '/diet'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          Card(
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            color: const Color(0xFFF6F5F8),
                            elevation: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "I TUOI PROGRESSI DI OGGI",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Column(
                                        children: [
                                          Text(
                                            "${homeState.workoutStreakGiorni}🔥",
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            "Streak allenamenti",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          Text(
                                            "${homeState.dietStreakGiorni}🥗",
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            "Streak dieta",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          ToolsGrid(
                            onAllenamento: () => Navigator.pushNamed(context, '/workout'),
                            onDieta: () => Navigator.pushNamed(context, '/diet'),
                            onCommunity: () => Navigator.pushNamed(context, '/community'),
                            onProgressi: () => Navigator.pushNamed(context, '/progress'),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
