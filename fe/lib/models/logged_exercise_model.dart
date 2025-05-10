class LoggedExercise {
  final int exerciseId;
  final String exerciseType;
  final int durationMin;
  final double caloriesBurned;
  final DateTime loggedAt;

  LoggedExercise({
    required this.exerciseId,
    required this.exerciseType,
    required this.durationMin,
    required this.caloriesBurned,
    required this.loggedAt,
  });

  factory LoggedExercise.fromJson(Map<String, dynamic> json) {
    return LoggedExercise(
      exerciseId: json['exercise_id'] as int,
      exerciseType: json['exercise_type'] as String,
      durationMin: json['duration_min'] as int,
      caloriesBurned: (json['calories_burned'] as num).toDouble(),
      loggedAt: DateTime.parse(json['logged_at'] as String),
    );
  }
}
