import '../../models/recent_log_model.dart';

abstract class RecentLogsState {}

class RecentLogsInitial extends RecentLogsState {}

class RecentLogsLoading extends RecentLogsState {}

class RecentLogsLoaded extends RecentLogsState {
  final List<RecentLog> logs;

  RecentLogsLoaded(this.logs);
}

class RecentLogsError extends RecentLogsState {
  final String message;

  RecentLogsError(this.message);
}
