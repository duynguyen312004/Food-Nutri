import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/user_service.dart';
import 'metrics_state.dart';

class MetricsCubit extends Cubit<MetricsState> {
  final UserService _userService;
  MetricsCubit(this._userService) : super(MetricsInitial());

  /// Load metrics cho một ngày cụ thể
  Future<void> loadMetricsForDate(DateTime date) async {
    try {
      emit(MetricsLoading());
      // Gọi API lấy dữ liệu theo ngày
      final metricsData = await _userService.getDailyMetrics(date);

      emit(MetricsLoaded(metricsData));
    } catch (e) {
      emit(MetricsError('Không thể tải dữ liệu: \$e'));
    }
  }
}
