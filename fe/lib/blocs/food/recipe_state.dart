import '../../models/ingredient_entry.dart';

sealed class RecipeState {}

class RecipeInitial extends RecipeState {}

class RecipeLoading extends RecipeState {}

class RecipeSuccess extends RecipeState {}

class RecipeIngredientsLoaded extends RecipeState {
  final List<IngredientEntry> ingredients;
  RecipeIngredientsLoaded(this.ingredients);
}

class RecipeError extends RecipeState {
  final String message;
  RecipeError(this.message);
}
