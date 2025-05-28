import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/goal_model.dart';
import '../../services/user_service.dart';
import 'goal_state.dart';

class GoalCubit extends Cubit<GoalState> {
  final UserService userService;
  GoalCubit(this.userService) : super(GoalInitial());

  /// Load mục tiêu hiện tại
  Future<void> fetchGoal() async {
    emit(GoalLoading());
    try {
      final goal = await userService.fetchGoal();
      emit(GoalLoaded(goal));
    } catch (e) {
      emit(GoalError(e.toString()));
    }
  }

  /// Cập nhật mục tiêu mới
  Future<void> updateGoal(GoalModel goal) async {
    emit(GoalLoading());
    try {
      final updatedGoal = await userService.updateGoal(goal);
      emit(GoalLoaded(updatedGoal));
    } catch (e) {
      emit(GoalError(e.toString()));
    }
  }
}
