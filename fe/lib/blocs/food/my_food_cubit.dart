import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/food_service.dart';
import 'my_food_state.dart';

class MyFoodsCubit extends Cubit<MyFoodsState> {
  MyFoodsCubit() : super(MyFoodsInitial());

  Future<void> loadMyFoods({int limit = 10}) async {
    emit(MyFoodsLoading());
    try {
      final results = await FoodService.getMyFoods(limit: limit);
      emit(MyFoodsLoaded(results));
    } catch (e) {
      emit(MyFoodsError(e.toString()));
    }
  }
}
