class RecentLog {
  final String type; // "meal" hoặc "exercise"
  final String name;
  final String? category;
  final String? imageUrl; // chỉ có nếu là meal
  final double? perCalories; // calo trên 1 đơn vị
  final double? quantity; // số lượng user đã ăn
  final String? unit; // unit của quantity
  final double? calories; // meal
  final double? caloriesBurned; // exercise
  final double? protein;
  final double? fat;
  final double? carbs;
  final int? durationMin;
  final DateTime createdAt;

  RecentLog({
    required this.type,
    required this.name,
    this.category,
    this.imageUrl,
    this.perCalories,
    this.quantity,
    this.unit,
    this.calories,
    this.caloriesBurned,
    this.protein,
    this.fat,
    this.carbs,
    this.durationMin,
    required this.createdAt,
  });

  factory RecentLog.fromJson(Map<String, dynamic> json) {
    return RecentLog(
      type: json['type'],
      name: json['name'],
      category: json['category'] as String?,
      imageUrl: json['image_url'],
      perCalories: (json['per_calories'] as num?)?.toDouble(),
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      calories: (json['calories'] as num?)?.toDouble(),
      caloriesBurned: (json['calories_burned'] as num?)?.toDouble(),
      protein: (json['protein'] as num?)?.toDouble(),
      fat: (json['fat'] as num?)?.toDouble(),
      carbs: (json['carbs'] as num?)?.toDouble(),
      durationMin: (json['duration_min'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
