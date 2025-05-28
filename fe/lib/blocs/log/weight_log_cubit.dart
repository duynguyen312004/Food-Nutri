import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/user_service.dart';
import 'weight_log_state.dart';

class WeightLogCubit extends Cubit<WeightLogState> {
  final UserService userService;
  WeightLogCubit(this.userService) : super(WeightLogInitial());

  // Lấy log trong khoảng
  Future<void> fetchWeightLogs(
      {DateTime? start, DateTime? end, bool showLoading = true}) async {
    if (showLoading) emit(WeightLogLoading());
    try {
      final logs = await userService.fetchWeightLogs(start: start, end: end);
      emit(WeightLogLoaded(logs));
    } catch (e) {
      emit(WeightLogError(e.toString()));
    }
  }

  // Ghi lại cân nặng, sau đó reload lại log trong khoảng hiện tại
  Future<void> addWeightLog({
    required double weightKg,
    required DateTime date,
    DateTime? rangeStart,
    DateTime? rangeEnd,
  }) async {
    emit(WeightLogLoading());
    try {
      await userService.addWeightLog(weightKg: weightKg, loggedAt: date);
      // Sau khi thêm, reload lại logs, KHÔNG cần loading nữa!
      await fetchWeightLogs(
          start: rangeStart, end: rangeEnd, showLoading: false);
    } catch (e) {
      emit(WeightLogError('Lỗi khi thêm log: $e'));
    }
  }
}
