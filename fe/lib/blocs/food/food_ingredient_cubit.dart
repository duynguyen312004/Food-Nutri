// lib/blocs/food/food_ingredient_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/ingredient_entry.dart';
import '../../services/food_service.dart';

abstract class FoodIngredientState {}

class IngredientInitial extends FoodIngredientState {}

class IngredientLoading extends FoodIngredientState {}

class IngredientLoaded extends FoodIngredientState {
  final List<IngredientEntry> ingredients;

  IngredientLoaded(this.ingredients);
}

class IngredientError extends FoodIngredientState {
  final String message;

  IngredientError(this.message);
}

class FoodIngredientCubit extends Cubit<FoodIngredientState> {
  FoodIngredientCubit() : super(IngredientInitial());

  Future<void> loadIngredients(int foodId) async {
    emit(IngredientLoading());
    try {
      final result = await FoodService.getIngredientsForRecipe(foodId);
      emit(IngredientLoaded(result));
    } catch (e) {
      emit(IngredientError(e.toString()));
    }
  }

  void clearFoodIngredients() {
    emit(IngredientInitial());
  }
}
