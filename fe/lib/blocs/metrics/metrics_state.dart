abstract class MetricsState {}

class MetricsInitial extends MetricsState {}

class MetricsLoading extends MetricsState {}

class MetricsLoaded extends MetricsState {
  final Map<String, dynamic> metrics;
  MetricsLoaded(this.metrics);
}

class MetricsError extends MetricsState {
  final String message;
  MetricsError(this.message);
}
