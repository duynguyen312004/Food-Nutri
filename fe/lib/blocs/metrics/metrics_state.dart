abstract class MetricsState {}

class MetricsInitial extends MetricsState {}

class MetricsLoading extends MetricsState {}

class MetricsLoaded extends MetricsState {
  final Map<String, dynamic> metrics;
  final DateTime date;
  MetricsLoaded(this.metrics, this.date);
}

class MetricsError extends MetricsState {
  final String message;
  MetricsError(this.message);
}
