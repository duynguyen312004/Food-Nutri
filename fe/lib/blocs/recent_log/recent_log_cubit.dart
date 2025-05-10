import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nutrition_app/services/log_service.dart';

import 'recent_log_state.dart';

class RecentLogsCubit extends Cubit<RecentLogsState> {
  final LogService _logService;

  RecentLogsCubit(this._logService) : super(RecentLogsInitial());

  Future<void> loadRecentLogs(DateTime date) async {
    emit(RecentLogsLoading());
    try {
      final logs = await _logService.getRecentLogs(date);
      logs.sort(
          (a, b) => b.createdAt.compareTo(a.createdAt)); // gần nhất lên đầu
      emit(RecentLogsLoaded(logs));
    } catch (e) {
      emit(RecentLogsError(e.toString()));
    }
  }
}
