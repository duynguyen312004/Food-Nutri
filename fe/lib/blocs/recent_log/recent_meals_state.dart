import '../../models/recent_log_model.dart';

sealed class RecentMealsState {}

class RecentMealsInitial extends RecentMealsState {}

class RecentMealsLoading extends RecentMealsState {}

class RecentMealsLoaded extends RecentMealsState {
  final List<RecentLog> meals;
  RecentMealsLoaded(this.meals);
}

class RecentMealsError extends RecentMealsState {
  final String message;
  RecentMealsError(this.message);
}
