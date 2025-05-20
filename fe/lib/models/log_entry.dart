class LogEntry {
  final int logId;
  final String type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  LogEntry({
    required this.logId,
    required this.type,
    required this.timestamp,
    required this.data,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      logId: json['logId'], // Map từ JSON
      type: json['type'],
      timestamp: DateTime.parse(json['timestamp']).toLocal(),
      data: json['data'] as Map<String, dynamic>,
    );
  }
}
