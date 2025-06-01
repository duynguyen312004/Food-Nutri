import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/food_service.dart';
import 'custom_food_state.dart';

class CustomFoodCubit extends Cubit<CustomFoodState> {
  CustomFoodCubit() : super(CustomFoodInitial());

  Future<void> createCustomFood({
    required String name,
    required String unit,
    required double calories,
    required double protein,
    required double fat,
    required double carbs,
    File? image,
  }) async {
    emit(CustomFoodLoading());
    try {
      await FoodService.createCustomFood(
        name: name,
        unit: unit,
        calories: calories,
        protein: protein,
        fat: fat,
        carbs: carbs,
        image: image,
      );
      emit(CustomFoodSuccess());
    } catch (e) {
      emit(CustomFoodError(e.toString()));
    }
  }

  Future<void> updateCustomFood({
    required int foodItemId,
    required String name,
    required String unit,
    required double calories,
    required double protein,
    required double fat,
    required double carbs,
    File? image,
  }) async {
    emit(CustomFoodLoading());
    try {
      await FoodService.updateCustomFood(
        foodId: foodItemId,
        name: name,
        unit: unit,
        calories: calories,
        protein: protein,
        fat: fat,
        carbs: carbs,
        image: image,
      );
      emit(CustomFoodSuccess());
    } catch (e) {
      emit(CustomFoodError(e.toString()));
    }
  }

  Future<void> deleteCustomFood(int foodItemId) async {
    emit(CustomFoodLoading());
    try {
      await FoodService.deleteCustomFood(foodItemId);
      emit(CustomFoodSuccess());
    } catch (e) {
      emit(CustomFoodError(e.toString()));
    }
  }
}
