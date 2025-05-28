class GoalModel {
  final int? goalId; // (tùy chọn) ID của mục tiêu trên BE, nếu BE trả về
  final double targetValue; // Cân nặng mục tiêu (kg)
  final String goalDirection; // 'giảm cân', 'tăng cân', 'giữ nguyên'
  final int durationWeeks; // Số tuần dự kiến hoàn thành
  final double weeklyRate; // Số kg giảm/tăng mỗi tuần
  final DateTime? startDate; // Ngày bắt đầu mục tiêu

  GoalModel({
    this.goalId,
    required this.targetValue,
    required this.goalDirection,
    required this.durationWeeks,
    required this.weeklyRate,
    this.startDate,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      goalId: json['goal_id'], // Có thì lấy, không thì thôi
      targetValue: (json['target_value'] as num).toDouble(),
      goalDirection: json['goal_direction'] ?? '',
      durationWeeks: json['duration_weeks'] ?? 0,
      weeklyRate: (json['weekly_rate'] as num).toDouble(),
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goal_id': goalId,
      'target_value': targetValue,
      'goal_direction': goalDirection,
      'duration_weeks': durationWeeks,
      'weekly_rate': weeklyRate,
      'start_date': startDate?.toIso8601String(),
    };
  }
}
