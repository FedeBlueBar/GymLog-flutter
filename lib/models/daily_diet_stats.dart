/// Questo file contiene il modello dati per le statistiche giornaliere sulla dieta.
/// Gestisce i traguardi nutrizionali (calorie e macronutrienti target) e calcola in tempo reale
/// i valori consumati basandosi sugli alimenti registrati nella giornata.

import 'package:gymlog_flutter/models/food_item.dart';

/// Modello che rappresenta il riepilogo nutrizionale di una singola giornata.
/// Contiene i valori target (obiettivo) e la lista dei cibi effettivamente consumati.
class DailyDietStats {
  // Traguardi giornalieri previsti (target)
  final int totalCalories;
  final double totalCarbs;
  final double totalProteins;
  final double totalFats;

  // Lista degli alimenti effettivamente consumati nella giornata
  final List<FoodItem> foods;

  DailyDietStats({
    this.totalCalories = 2000,
    this.totalCarbs = 250.0,
    this.totalProteins = 150.0,
    this.totalFats = 70.0,
    this.foods = const [],
  });

  // Calcoli dinamici: sommano calorie e macro degli alimenti inseriti per restituire il totale corrente consumato
  int get consumedCalories => foods.fold(0, (sum, item) => sum + item.calories);
  double get consumedCarbs => foods.fold(0.0, (sum, item) => sum + item.carbs);
  double get consumedProteins => foods.fold(0.0, (sum, item) => sum + item.proteins);
  double get consumedFats => foods.fold(0.0, (sum, item) => sum + item.fats);

  /// Crea un'istanza di DailyDietStats partendo da una mappa (usato quando si leggono dati da Firestore)
  factory DailyDietStats.fromMap(Map<String, dynamic> map) {
    final foodsList = (map['foods'] as List?)
            ?.map((item) => FoodItem.fromMap(Map<String, dynamic>.from(item as Map)))
            .toList() ??
        [];
    return DailyDietStats(
      totalCalories: (map['totalCalories'] as num?)?.toInt() ?? 2000,
      totalCarbs: (map['totalCarbs'] as num?)?.toDouble() ?? 250.0,
      totalProteins: (map['totalProteins'] as num?)?.toDouble() ?? 150.0,
      totalFats: (map['totalFats'] as num?)?.toDouble() ?? 70.0,
      foods: foodsList,
    );
  }

  /// Converte l'istanza in una mappa (usato per salvare i dati su Firestore)
  Map<String, dynamic> toMap() {
    return {
      'totalCalories': totalCalories,
      'totalCarbs': totalCarbs,
      'totalProteins': totalProteins,
      'totalFats': totalFats,
      'foods': foods.map((food) => food.toMap()).toList(),
    };
  }
}
