import '../../models/user_model.dart';
import '../../models/goal_model.dart';
import '../../models/user_settings.dart';

abstract class UserDataState {}

class UserDataInitial extends UserDataState {}

class UserDataLoading extends UserDataState {}

class UserDataLoaded extends UserDataState {
  final UserModel profile;
  final GoalModel goal;
  final UserSettings settings;

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
