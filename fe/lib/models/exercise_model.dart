class ExerciseType {
  final int id;
  final String name;
  final double mets;
  final String? category;
  final String? iconUrl;

  ExerciseType({
    required this.id,
    required this.name,
    required this.mets,
    this.category,
    this.iconUrl,
  });

  factory ExerciseType.fromJson(Map<String, dynamic> json) {
    return ExerciseType(
      id: json['id'],
      name: json['name'],
      mets: (json['mets'] as num).toDouble(),
      category: json['category'] as String?,
      iconUrl: json['icon_url'] as String?,
    );
  }
}
