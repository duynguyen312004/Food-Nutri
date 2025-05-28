class WeightLogModel {
  final int weightId;
  final double weightKg;
  final DateTime loggedAt;

  WeightLogModel({
    required this.weightId,
    required this.weightKg,
    required this.loggedAt,
  });

  factory WeightLogModel.fromJson(Map<String, dynamic> json) {
    return WeightLogModel(
      weightId: json['weightId'] ?? json['weight_id'] ?? 0,
      weightKg: (json['weightKg'] ?? json['weight_kg'])?.toDouble() ?? 0.0,
      loggedAt: DateTime.parse(json['loggedAt'] ??
          json['logged_at'] ??
          DateTime.now().toIso8601String()),
    );
  }
}
