import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:nutrition_app/models/log_entry.dart';
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

  Future<List<LogEntry>> fetchLogs(DateTime date) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final uri = Uri.parse('$_baseUrl?date=$dateStr');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (idToken != null) 'Authorization': 'Bearer $idToken',
      },
    );
    if (response.statusCode == 200) {
      final rawList = jsonDecode(response.body) as List<dynamic>;
      return rawList.map((e) => LogEntry.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch logs: \${response.statusCode}');
    }
  }

  Future<void> deleteLog(String type, int logId) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) {
      throw Exception('Missing Firebase token');
    }

    final uri = Uri.parse('$_baseUrl/$type/$logId');

    final response = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Xoá log thất bại: ${response.body}');
    }
  }

  Future<void> updateMealQuantity(
      int logId, double quantity, DateTime timestamp) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) {
      throw Exception('Missing Firebase token');
    }

    final uri = Uri.parse('$_baseUrl/meal/$logId');
    final body = jsonEncode({
      'quantity': quantity,
      'timestamp': timestamp.toIso8601String(),
    });

    final response = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Cập nhật khẩu phần thất bại: ${response.body}');
    }
  }

  Future<void> addWaterLog(DateTime timestamp, int intakeMl) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) {
      throw Exception('Missing Firebase token');
    }

    final body = {
      'type': 'water',
      'timestamp': timestamp.toIso8601String(),
      'data': {
        'intake_ml': intakeMl,
      },
    };

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 201) {
      throw Exception('Ghi log nước thất bại: ${response.body}');
    }
  }

  Future<void> addMealLog(DateTime timestamp, Map<String, dynamic> data) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) {
      throw Exception('Missing Firebase token');
    }

    final body = {
      'type': 'meal',
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 201) {
      throw Exception('Ghi log món ăn thất bại: ${response.body}');
    }
  }

  Future<void> addExerciseLog(
      DateTime timestamp, int exerciseTypeId, int durationMin) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) {
      throw Exception('Missing Firebase token');
    }

    final body = {
      'type': 'exercise',
      'timestamp': timestamp.toIso8601String(),
      'data': {
        'exercise_type_id': exerciseTypeId,
        'duration_min': durationMin,
      }
    };

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 201) {
      throw Exception('Ghi log bài tập thất bại: ${response.body}');
    }
  }
}
