import '../../models/food_item_model.dart';

sealed class FoodState {}

class FoodInitial extends FoodState {}

class FoodLoading extends FoodState {}

class FoodLoaded extends FoodState {
  final FoodItem food;
  FoodLoaded(this.food);
}

class FoodListLoaded extends FoodState {
  final List<FoodItem> results;
  FoodListLoaded(this.results);
}

class FoodError extends FoodState {
  final String message;
  FoodError(this.message);
}
