class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  final double? startingWeight;
  final double? targetWeight;

  final String? gender;
  final DateTime? dateOfBirth;
  final double? heightCm;

  final String? firstName;
  final String? lastName;

  UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.startingWeight,
    this.targetWeight,
    this.gender,
    this.dateOfBirth,
    this.heightCm,
    this.firstName,
    this.lastName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid']?.toString() ?? json['user_id']?.toString() ?? '',
      email: json['email'],
      displayName: json['displayName'] ?? json['display_name'],
      photoUrl: json['photoUrl'] ?? json['avatar_url'],
      startingWeight:
          (json['startingWeight'] ?? json['starting_weight'])?.toDouble(),
      targetWeight: (json['targetWeight'] ?? json['target_weight'])?.toDouble(),
      gender: json['gender'],
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'])
          : (json['date_of_birth'] != null
              ? DateTime.tryParse(json['date_of_birth'])
              : null),
      heightCm: (json['heightCm'] ?? json['height_cm'])?.toDouble(),
      firstName: json['first_name'],
      lastName: json['last_name'],
    );
  }
}
