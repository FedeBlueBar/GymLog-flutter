class FoodItem {
  final String id;
  final String name;
  final String category;
  final int grams;
  final String unit;
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
