import 'package:nutrition_app/models/weight_log_model.dart';

sealed class WeightLogState {}

class WeightLogInitial extends WeightLogState {}

class WeightLogLoading extends WeightLogState {}

class WeightLogLoaded extends WeightLogState {
  final List<WeightLogModel> logs;

  WeightLogLoaded(this.logs);
}

class WeightLogError extends WeightLogState {
  final String message;

  WeightLogError(this.message);
}
