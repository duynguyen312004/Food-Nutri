import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class UserService {
  // ignore: unused_field
  static const String _baseUrl = 'http://10.0.2.2:5000/api/v1/users';

  /// Lấy thông tin profile hiện tại
  Future<Map<String, dynamic>> fetchProfile() async {
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
      return jsonDecode(response.body) as Map<String, dynamic>;
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
  Future<Map<String, dynamic>> fetchGoal() async {
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
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch goal: ${response.statusCode}');
    }
  }

  //lấy Settings
  Future<Map<String, dynamic>> fetchSettings() async {
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
      return jsonDecode(response.body) as Map<String, dynamic>;
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
}
