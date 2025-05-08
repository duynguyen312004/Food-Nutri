abstract class UserDataState {}

class UserDataInitial extends UserDataState {}

class UserDataLoading extends UserDataState {}

class UserDataLoaded extends UserDataState {
  final Map<String, dynamic> profile;
  final Map<String, dynamic> goal;
  final Map<String, dynamic> settings;

  UserDataLoaded({
    required this.profile,
    required this.goal,
    required this.settings,
  });
}

class UserDataError extends UserDataState {
  final String message;
  UserDataError(this.message);
}
