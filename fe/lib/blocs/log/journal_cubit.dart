import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/food_item_model.dart';
import '../../services/log_service.dart';
import '../../models/log_entry.dart';
import '../../blocs/food/food_cubit.dart';
import 'journal_state.dart';

class JournalCubit extends Cubit<JournalState> {
  final LogService _logService;
  final FoodCubit foodCubit;

  JournalCubit(this._logService, this.foodCubit) : super(JournalInitial());

  Future<void> loadLogs(DateTime date) async {
    emit(JournalLoading());
    try {
      final logs = await _logService.fetchLogs(date);
      emit(JournalLoaded(logs));
    } catch (e) {
      emit(JournalError(e.toString()));
    }
  }

  Future<void> addWaterLog(DateTime timestamp, int intakeMl) async {
    try {
      await _logService.addWaterLog(timestamp, intakeMl);
      await loadLogs(timestamp);
    } catch (e) {
      emit(JournalError('Lỗi khi thêm nước: $e'));
    }
  }

  Future<void> deleteLog(LogEntry log) async {
    try {
      final type = log.type;
      final logId = log.logId;
      await _logService.deleteLog(type, logId);
      await loadLogs(log.timestamp);
    } catch (e) {
      emit(JournalError('Lỗi khi xoá log: $e'));
    }
  }

  Future<void> updateMealQuantity(int logId, double quantity,
      {required DateTime timestamp}) async {
    try {
      await _logService.updateMealQuantity(logId, quantity, timestamp);
      await loadLogs(timestamp);
    } catch (e) {
      emit(JournalError('Lỗi khi cập nhật log món ăn: $e'));
    }
  }

  Future<void> addMealLog(DateTime timestamp,
      {required FoodItem food,
      required double quantity,
      String? mealName}) async {
    final factor = quantity / food.servingSize;
    final data = {
      "food_item_id": food.foodItemId,
      "quantity": quantity,
      "unit": food.servingUnit,
      "calories": (food.calories * factor).round(),
      "protein": food.protein * factor,
      "carbs": food.carbs * factor,
      "fat": food.fat * factor,
      "name": food.name,
      "image_url": food.imageUrl,
      if (mealName != null) "meal_name": mealName, // 👈 truyền vào
    };

    try {
      await _logService.addMealLog(timestamp, data);
      await loadLogs(timestamp);
    } catch (e) {
      emit(JournalError('Lỗi khi thêm món ăn: $e'));
    }
  }
}
