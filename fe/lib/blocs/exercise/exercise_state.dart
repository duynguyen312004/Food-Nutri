import 'package:equatable/equatable.dart';

import '../../models/exercise_model.dart';
import '../../models/logged_exercise_model.dart';

abstract class ExerciseState extends Equatable {
  const ExerciseState();

  @override
  List<Object?> get props => [];
}

/// Khi mới vào, chưa làm gì
class ExerciseInitial extends ExerciseState {}

/// Đang load danh sách types
class ExerciseLoading extends ExerciseState {}

/// Load types thành công
class ExerciseTypesLoaded extends ExerciseState {
  final List<ExerciseType> types;
  const ExerciseTypesLoaded(this.types);

  @override
  List<Object?> get props => [types];
}

/// Đang gửi request log exercise
class ExerciseLogging extends ExerciseState {}

/// Log xong, có dữ liệu trả về
class ExerciseLogged extends ExerciseState {
  final LoggedExercise log;
  const ExerciseLogged(this.log);

  @override
  List<Object?> get props => [log];
}

/// Có lỗi (load types hoặc log exercise)
class ExerciseError extends ExerciseState {
  final String message;
  const ExerciseError(this.message);

  @override
  List<Object?> get props => [message];
}
