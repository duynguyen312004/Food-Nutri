import '../../models/food_item_model.dart';

abstract class MyFoodsState {}

class MyFoodsInitial extends MyFoodsState {}

class MyFoodsLoading extends MyFoodsState {}

class MyFoodsLoaded extends MyFoodsState {
  final List<FoodItem> foods;
  MyFoodsLoaded(this.foods);
}

class MyFoodsError extends MyFoodsState {
  final String message;
  MyFoodsError(this.message);
}
