abstract class CustomFoodState {}

class CustomFoodInitial extends CustomFoodState {}

class CustomFoodLoading extends CustomFoodState {}

class CustomFoodSuccess extends CustomFoodState {}

class CustomFoodError extends CustomFoodState {
  final String message;
  CustomFoodError(this.message);
}
