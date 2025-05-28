import '../../models/goal_model.dart';

abstract class GoalState {}

class GoalInitial extends GoalState {}

class GoalLoading extends GoalState {}

class GoalLoaded extends GoalState {
  final GoalModel goal;
  GoalLoaded(this.goal);
}

class GoalError extends GoalState {
  final String message;
  GoalError(this.message);
}
