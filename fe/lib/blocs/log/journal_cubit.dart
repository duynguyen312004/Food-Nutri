import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/food_item_model.dart';
import '../../services/log_service.dart';
import '../../models/log_entry.dart';
import '../../blocs/food/food_cubit.dart';
import '../metrics/metrics_cubit.dart';
import 'journal_state.dart';

class JournalCubit extends Cubit<JournalState> {
  final LogService _logService;
  final FoodCubit foodCubit;
  final MetricsCubit metricsCubit;
  JournalCubit(this._logService, this.foodCubit, this.metricsCubit)
      : super(JournalInitial());

  Future<void> loadLogs(DateTime date) async {
    emit(JournalLoading());
    try {
      final logs = await _logService.fetchLogs(date);
      emit(JournalLoaded(logs, date));
    } catch (e) {
      emit(JournalError(e.toString()));
    }
  }

  Future<void> addWaterLog(DateTime timestamp, int intakeMl) async {
    try {
      await _logService.addWaterLog(timestamp, intakeMl);
      await metricsCubit.loadMetricsForDate(timestamp);
      await loadLogs(timestamp);
    } catch (e) {
      emit(JournalError('Lỗi khi thêm nước: $e'));
    }
  }

  Future<void> deleteLog(LogEntry log) async {
    final currentState = state;
    if (currentState is JournalLoaded) {
      // 1. Tạm thời loại bỏ khỏi UI
      final updatedLogs =
          currentState.logs.where((e) => e.logId != log.logId).toList();
      emit(JournalLoaded(updatedLogs, currentState.date));
    }

    try {
      await _logService.deleteLog(log.type, log.logId);
      // 2. Tải lại logs thật sau khi xoá xong
      await metricsCubit.loadMetricsForDate(log.timestamp);
      await loadLogs(log.timestamp);
    } catch (e) {
      emit(JournalError('Lỗi khi xoá log: $e'));
    }
  }

  Future<void> updateMealQuantity(int logId, double quantity,
      {required DateTime timestamp}) async {
    try {
      await _logService.updateMealQuantity(logId, quantity, timestamp);
      await metricsCubit.loadMetricsForDate(timestamp);
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
      if (mealName != null) "meal_name": mealName,
    };

    try {
      await _logService.addMealLog(timestamp, data);
      await metricsCubit.loadMetricsForDate(timestamp);
      await loadLogs(timestamp);
    } catch (e) {
      emit(JournalError('Lỗi khi thêm món ăn: $e'));
    }
  }

  Future<void> addExerciseLog(DateTime timestamp,
      {required int exerciseTypeId, required int durationMin}) async {
    try {
      await _logService.addExerciseLog(timestamp, exerciseTypeId, durationMin);
      await metricsCubit.loadMetricsForDate(timestamp);
      emit(
          JournalLoading()); // reset state để cây widget loại bỏ Dismissible cũ
      await Future.delayed(
          const Duration(milliseconds: 10)); // cho phép unmount
      await loadLogs(timestamp);
    } catch (e) {
      emit(JournalError('Lỗi khi thêm bài tập: $e'));
    }
  }

  void clearJournalData() {
    emit((JournalInitial()));
  }
}
