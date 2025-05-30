import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/food_service.dart';
import 'food_state.dart';

class FoodCubit extends Cubit<FoodState> {
  FoodCubit() : super(FoodInitial());

  Future<void> loadFoodDetail(int foodId) async {
    emit(FoodLoading());
    try {
      final food = await FoodService.getFoodDetail(foodId);
      emit(FoodLoaded(food));
    } catch (e) {
      emit(FoodError(e.toString()));
    }
  }

  Future<void> searchFoods(String query) async {
    emit(FoodLoading());
    try {
      final results = await FoodService.searchFoods(query);
      emit(FoodListLoaded(results));
    } catch (e) {
      emit(FoodError(e.toString()));
    }
  }

  void clear() {
    emit(FoodInitial());
  }
}
