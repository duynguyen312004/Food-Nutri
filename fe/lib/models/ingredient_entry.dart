import '../../models/food_item_model.dart';

/// Dùng trong CreateRecipePage để lưu nguyên liệu được chọn
class IngredientEntry {
  final FoodItem food;
  double quantity;
  String unit;

  IngredientEntry({
    required this.food,
    required this.quantity,
    this.unit = 'g',
  });

  /// Dùng khi gửi lên backend
  Map<String, dynamic> toJson() => {
        'food_item_id': food.foodItemId,
        'quantity': quantity,
        'unit': unit,
      };

  /// Tính tổng calories cho nguyên liệu (theo tỉ lệ)
  double get totalCalories => (quantity / food.servingSize) * food.calories;

  /// Tính macros tương ứng
  double get totalCarbs => (quantity / food.servingSize) * food.carbs;

  double get totalProtein => (quantity / food.servingSize) * food.protein;

  double get totalFat => (quantity / food.servingSize) * food.fat;

  factory IngredientEntry.fromJson(Map<String, dynamic> json) {
    return IngredientEntry(
      food: FoodItem.fromJson(json['food_item']),
      quantity: (json['quantity'] is num)
          ? (json['quantity'] as num).toDouble()
          : double.tryParse(json['quantity'].toString()) ?? 0.0,
      unit: json['unit'] ?? 'g',
    );
  }
}
