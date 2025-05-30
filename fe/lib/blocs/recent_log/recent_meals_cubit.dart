import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nutrition_app/services/log_service.dart';

import 'recent_meals_state.dart';

class RecentMealsCubit extends Cubit<RecentMealsState> {
  final LogService _logService;

  RecentMealsCubit(this._logService) : super(RecentMealsInitial());

  Future<void> loadRecentMeals(DateTime date) async {
    emit(RecentMealsLoading()); // Force UI loading (xóa state cũ)
    try {
      final meals = await _logService.getRecentLogs(date);
      emit(RecentMealsLoaded(meals));
    } catch (e) {
      emit(RecentMealsError(e.toString()));
    }
  }

  void removeMealFromUI(int foodItemId) {
    if (state is RecentMealsLoaded) {
      final meals = List.of((state as RecentMealsLoaded).meals);
      meals.removeWhere((m) => m.foodItemId == foodItemId);
      emit(RecentMealsLoaded(meals));
    }
  }

  void clearRecentMeals() {
    emit(RecentMealsInitial());
  }
}
