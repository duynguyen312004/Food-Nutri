import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/log_service.dart';
import 'journal_state.dart';

class JournalCubit extends Cubit<JournalState> {
  final LogService _logService;
  JournalCubit(this._logService) : super(JournalInitial());

  Future<void> loadLogs(DateTime date) async {
    emit(JournalLoading());
    try {
      final logs = await _logService.fetchLogs(date);
      emit(JournalLoaded(logs));
    } catch (e) {
      emit(JournalError(e.toString()));
    }
  }
}
