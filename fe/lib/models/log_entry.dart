class LogEntry {
  final String type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  LogEntry({required this.type, required this.timestamp, required this.data});

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    final parsed = DateTime.parse(json['timestamp'] as String);
    final local = parsed.toLocal(); // <-- chuyển thành giờ local
    return LogEntry(
      type: json['type'] as String,
      timestamp: local,
      data: Map<String, dynamic>.from(json['data'] as Map),
    );
  }
}
