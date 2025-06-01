import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/food_service.dart';
import 'recipe_state.dart';

class RecipeCubit extends Cubit<RecipeState> {
  RecipeCubit() : super(RecipeInitial());

  /// Gửi dữ liệu tạo công thức món ăn mới lên server
  Future<void> createRecipe({
    required String name,
    required double servingSize,
    required String unit,
    required List<Map<String, dynamic>> ingredients,
    File? image,
  }) async {
    emit(RecipeLoading()); // loading UI
    try {
      await FoodService.createRecipe(
        name: name,
        servingSize: servingSize,
        unit: unit,
        ingredients: ingredients,
        image: image,
      );
      emit(RecipeSuccess()); // tạo thành công
    } catch (e) {
      emit(RecipeError(e.toString())); // lỗi
    }
  }

  Future<void> updateRecipe({
    required int foodItemId,
    required String name,
    required double servingSize,
    required String unit,
    required List<Map<String, dynamic>> ingredients,
    File? image,
  }) async {
    emit(RecipeLoading());
    try {
      await FoodService.updateRecipe(
        foodItemId: foodItemId,
        name: name,
        servingSize: servingSize,
        unit: unit,
        ingredients: ingredients,
        image: image,
      );
      emit(RecipeSuccess());
    } catch (e) {
      emit(RecipeError(e.toString()));
    }
  }

  Future<void> loadRecipeIngredients(int recipeId) async {
    try {
      emit(RecipeLoading());
      final ingredients = await FoodService.getIngredientsForRecipe(recipeId);
      emit(RecipeIngredientsLoaded(ingredients));
    } catch (e) {
      emit(RecipeError('Không thể tải nguyên liệu: $e'));
    }
  }

  /// Reset state về ban đầu (nếu muốn làm lại form)
  void reset() {
    emit(RecipeInitial());
  }
}
