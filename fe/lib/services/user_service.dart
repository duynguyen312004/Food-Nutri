import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:nutrition_app/models/weight_log_model.dart';

import '../models/goal_model.dart';
import '../models/user_model.dart';
import '../models/user_settings.dart';

class UserService {
  // ignore: unused_field
  static const String _baseUrl = 'http://10.0.2.2:5000/api/v1/users';

  /// Lấy thông tin profile hiện tại
  Future<UserModel> fetchProfile() async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    final uri = Uri.parse('$_baseUrl/profile');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (idToken != null) 'Authorization': 'Bearer $idToken',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserModel.fromJson(data);
    } else {
      throw Exception('Failed to fetch profile: ${response.statusCode}');
    }
  }

  /// Cập nhật thông tin profile (PUT)
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    final uri = Uri.parse('$_baseUrl/profile');
    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (idToken != null) 'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to update profile: ${response.statusCode}');
    }
  }

  /// Hoàn thiện initial setup (POST)
  Future<Map<String, dynamic>> initialSetup(Map<String, dynamic> data) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    final uri = Uri.parse('$_baseUrl/setup');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (idToken != null) 'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to complete setup: ${response.statusCode}');
    }
  }

  //lấy Goal
  Future<GoalModel> fetchGoal() async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    final uri = Uri.parse('$_baseUrl/goals');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (idToken != null) 'Authorization': 'Bearer $idToken',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return GoalModel.fromJson(data);
    } else {
      throw Exception('Failed to fetch goal: ${response.statusCode}');
    }
  }

  //lấy Settings
  Future<UserSettings> fetchSettings() async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    final uri = Uri.parse('$_baseUrl/settings');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (idToken != null) 'Authorization': 'Bearer $idToken',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserSettings.fromJson(data);
    } else {
      throw Exception('Failed to fetch settings: ${response.statusCode}');
    }
  }

  /// Lấy metrics dinh dưỡng cho một ngày cụ thể
  Future<Map<String, dynamic>> getDailyMetrics(DateTime date) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final uri = Uri.parse('$_baseUrl/metrics?date=$dateStr');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (idToken != null) 'Authorization': 'Bearer $idToken',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch metrics: ${response.statusCode}');
    }
  }

  /// Weight Log
  Future<List<WeightLogModel>> fetchWeightLogs(
      {DateTime? start, DateTime? end}) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    String url = '$_baseUrl/weight_logs';
    if (start != null && end != null) {
      final startStr = DateFormat('yyyy-MM-dd').format(start);
      final endStr = DateFormat('yyyy-MM-dd').format(end);
      url += '?start_date=$startStr&end_date=$endStr';
    }
    final uri = Uri.parse(url);
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (idToken != null) 'Authorization': 'Bearer $idToken',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => WeightLogModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch weight logs: ${response.statusCode}');
    }
  }

  /// Ghi lại cân nặng mới (upsert theo ngày)
  Future<WeightLogModel> addWeightLog({
    required double weightKg,
    required DateTime loggedAt,
  }) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    final uri = Uri.parse('$_baseUrl/weight_logs');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (idToken != null) 'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'weight_kg': weightKg,
        'logged_at': DateFormat('yyyy-MM-dd').format(loggedAt),
      }),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return WeightLogModel.fromJson(data);
    } else {
      throw Exception('Failed to add weight log: ${response.statusCode}');
    }
  }

  /// Update goal
  /// Cập nhật mục tiêu mới cho user (PUT)
  Future<GoalModel> updateGoal(GoalModel goal) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    final uri = Uri.parse('$_baseUrl/goals');
    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (idToken != null) 'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(goal.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return GoalModel.fromJson(data);
    } else {
      throw Exception('Failed to update goal: ${response.statusCode}');
    }
  }

  /// Xoá toàn bộ tài khoản người dùng (dữ liệu + user) từ backend
  Future<void> deleteAccount() async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    final uri = Uri.parse('$_baseUrl/delete_account');

    final response = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (idToken != null) 'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete account: ${response.statusCode}');
    }
  }
}
