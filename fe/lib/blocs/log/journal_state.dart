import 'package:nutrition_app/models/log_entry.dart';

abstract class JournalState {}

class JournalInitial extends JournalState {}

class JournalLoading extends JournalState {}

class JournalLoaded extends JournalState {
  final List<LogEntry> logs;
  final DateTime date;

  JournalLoaded(this.logs, this.date);
}

class JournalError extends JournalState {
  final String message;

  JournalError(this.message);
}
