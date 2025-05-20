class FoodItem {
  final int foodItemId;
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double servingSize;
  final String servingUnit;
  final bool isCustom;
  final String? imageUrl;

  FoodItem({
    required this.foodItemId,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.servingSize,
    required this.servingUnit,
    required this.isCustom,
    this.imageUrl,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      foodItemId: json['food_item_id'],
      name: json['name'],
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      servingSize: (json['serving_size'] as num).toDouble(),
      servingUnit: json['serving_unit'],
      isCustom: json['is_custom'] as bool,
      imageUrl: json['image_url'],
    );
  }
}
