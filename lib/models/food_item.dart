// Questo file contiene il modello dati per un singolo Alimento (FoodItem).
// Gestisce tutte le proprietà nutrizionali di un cibo consumato in una giornata,
// come la porzione, le calorie e la suddivisione dei macronutrienti.

// Modello che rappresenta le caratteristiche di un alimento.
// Viene utilizzato principalmente nel diario alimentare per tracciare i pasti dell'utente.
class FoodItem {
  // Informazioni generali sull'alimento
  final String id;
  final String name;
  final String category;

  // Dettagli quantitativi della porzione consumata
  final int grams;
  final String unit;

  // Valori nutrizionali calcolati per la porzione inserita
  final int calories;
  final double carbs;
  final double proteins;
  final double fats;

  FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.grams,
    required this.unit,
    required this.calories,
    required this.carbs,
    required this.proteins,
    required this.fats,
  });

  // Crea un'istanza partendo dai dati salvati nel database (in formato Mappa JSON).
  // Si occupa di fare il casting sicuro dei numeri (int e double) per evitare crash.
  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      grams: (map['grams'] as num?)?.toInt() ?? 0,
      unit: map['unit'] ?? 'g',
      calories: (map['calories'] as num?)?.toInt() ?? 0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
      proteins: (map['proteins'] as num?)?.toDouble() ?? 0.0,
      fats: (map['fats'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Converte l'oggetto in una Mappa pronta per essere salvata su database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'grams': grams,
      'unit': unit,
      'calories': calories,
      'carbs': carbs,
      'proteins': proteins,
      'fats': fats,
    };
  }
}
