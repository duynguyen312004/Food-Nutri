import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:nutrition_app/models/recent_log_model.dart';

class LogService {
  static const String _baseUrl = 'http://10.0.2.2:5000/api/v1/logs';

  Future<List<RecentLog>> getRecentLogs(DateTime date) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final uri = Uri.parse('$_baseUrl/recent?date=$dateStr');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (idToken != null) 'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> rawData = decoded['data'];
      return rawData.map((e) => RecentLog.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch recent logs: ${response.statusCode}');
    }
  }
}
