class GoalModel {
  final double targetValue;
  final String goalDirection;
  final int durationWeeks;
  final double weeklyRate;
  final DateTime? startDate;

  GoalModel({
    required this.targetValue,
    required this.goalDirection,
    required this.durationWeeks,
    required this.weeklyRate,
    this.startDate,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      targetValue: (json['target_value'] as num).toDouble(),
      goalDirection: json['goal_direction'] ?? '',
      durationWeeks: json['duration_weeks'] ?? 0,
      weeklyRate: (json['weekly_rate'] as num).toDouble(),
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'])
          : null,
    );
  }
}
