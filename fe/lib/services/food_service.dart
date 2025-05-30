import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../models/food_item_model.dart';

class FoodService {
  static const String _baseUrl = 'http://10.0.2.2:5000/api/v1/foods';

  static Future<FoodItem> getFoodDetail(int foodId) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) {
      throw Exception('Missing Firebase token');
    }

    final uri = Uri.parse('$_baseUrl/$foodId');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      return FoodItem.fromJson(jsonData);
    } else {
      throw Exception('Không tìm thấy món ăn (mã ${response.statusCode})');
    }
  }

  static Future<List<FoodItem>> searchFoods(String query) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) {
      throw Exception('Missing Firebase token');
    }

    final uri = Uri.parse('$_baseUrl?query=${Uri.encodeComponent(query)}');

    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    });
    if (response.statusCode == 200) {
      final List<dynamic> rawList = jsonDecode(response.body);
      return rawList.map((e) => FoodItem.fromJson(e)).toList();
    } else {
      throw Exception('Lỗi khi tìm kiếm món ăn');
    }
  }
}
