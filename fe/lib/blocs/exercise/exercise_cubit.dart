import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/exercise_service.dart';
import 'exercise_state.dart';

class ExerciseCubit extends Cubit<ExerciseState> {
  final ExerciseService _svc;

  ExerciseCubit(this._svc) : super(ExerciseInitial()) {
    loadExerciseTypes();
  }

  /// Lấy danh sách exercise types từ backend
  Future<void> loadExerciseTypes() async {
    emit(ExerciseLoading());
    try {
      final types = await _svc.fetchTypes();
      emit(ExerciseTypesLoaded(types));
    } catch (e) {
      emit(ExerciseError(e.toString()));
    }
  }

  /// Ghi lại log của 1 lần tập: typeId, durationMin
  Future<void> logExercise(int exerciseTypeId, int durationMin) async {
    emit(ExerciseLogging());
    try {
      final logged = await _svc.logExercise(exerciseTypeId, durationMin);
      emit(ExerciseLogged(logged));
      // Sau khi log xong, bạn có thể đồng thời load lại types nếu muốn:
      // await loadExerciseTypes();
    } catch (e) {
      emit(ExerciseError(e.toString()));
    }
  }
}
