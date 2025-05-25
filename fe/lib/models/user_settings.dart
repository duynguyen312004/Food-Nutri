class UserSettings {
  final String locale;
  final String timezone;
  final String weightUnit;
  final String energyUnit;
  final int? defaultTargetCalories;
  final bool drinkWaterReminder;
  final bool mealReminder;

  UserSettings({
    required this.locale,
    required this.timezone,
    required this.weightUnit,
    required this.energyUnit,
    this.defaultTargetCalories,
    required this.drinkWaterReminder,
    required this.mealReminder,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      locale: json['locale'],
      timezone: json['timezone'],
      weightUnit: json['weight_unit'],
      energyUnit: json['energy_unit'],
      defaultTargetCalories: json['default_target_calories'],
      drinkWaterReminder: json['drink_water_reminder'] ?? true,
      mealReminder: json['meal_reminder'] ?? true,
    );
  }
}
