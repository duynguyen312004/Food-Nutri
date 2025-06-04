import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/exercise_model.dart';
import '../models/logged_exercise_model.dart';

class ExerciseService {
  // static const String _baseUrl = 'http://10.0.2.2:5000/api/v1/exercise';
  // static const String _baseUrl =
  //     "http://192.168.1.103:5000/api/v1/exercise"; // Địa chỉ IP thật của PC
  static const String _baseUrl =
      "http://10.13.2.127:5000/api/v1/exercise"; // Địa chỉ IP thật của PC (TC)

  /// Fetch danh sách ExerciseType từ backend
  Future<List<ExerciseType>> fetchTypes() async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    final uri = Uri.parse('$_baseUrl/types');

    final resp = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (idToken != null) 'Authorization': 'Bearer $idToken',
      },
    );

    if (resp.statusCode == 200) {
      final List<dynamic> data = jsonDecode(resp.body);
      return data.map((e) => ExerciseType.fromJson(e)).toList();
    }
    throw Exception('Failed to load exercise types: \${resp.statusCode}');
  }

  /// Ghi nhật ký bài tập: gửi loại và thời gian
  Future<LoggedExercise> logExercise(
      int exerciseTypeId, int durationMin) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    final uri = Uri.parse(_baseUrl);

    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (idToken != null) 'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'exercise_type_id': exerciseTypeId,
        'duration_min': durationMin,
      }),
    );

    if (resp.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(resp.body);
      return LoggedExercise.fromJson(data);
    }
    throw Exception('Failed to log exercise: \${resp.statusCode}');
  }
}
