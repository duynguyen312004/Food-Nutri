import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../models/food_item_model.dart';
import '../models/ingredient_entry.dart';

class FoodService {
  // static const String _baseUrl = 'http://10.0.2.2:5000/api/v1/foods';
  // static const String _baseUrl =
  //     "http://192.168.1.103:5000/api/v1/foods"; // Địa chỉ IP thật của PC

  static const String _baseUrl =
      "http://10.13.2.127:5000/api/v1/foods"; // Địa chỉ IP thật của PC (TC)

  // ==== Helper lấy access token từ Firebase (bắt buộc để gọi API BE) ====
  static Future<String> _getIdToken() async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) throw Exception('Chưa đăng nhập');
    return idToken;
  }

  // ==== Helper để parse lỗi trả về từ API, ưu tiên lấy message từ BE (nếu có) ====
  static void _handleError(http.Response resp, {String? defaultMsg}) {
    String msg = defaultMsg ?? "Đã có lỗi xảy ra";
    try {
      final data = jsonDecode(resp.body);
      if (data is Map && data['message'] != null) msg = data['message'];
    } catch (_) {}
    throw Exception(msg);
  }

  /// ==============================
  ///         API CALLS
  /// ==============================

  /// Lấy chi tiết 1 món ăn theo ID
  /// (Thường dùng trong FoodDetailPage)
  static Future<FoodItem> getFoodDetail(int foodId) async {
    final idToken = await _getIdToken();
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
      _handleError(response, defaultMsg: 'Không tìm thấy món ăn');
    }
    throw Exception('Unexpected error');
  }

  /// Tìm kiếm món ăn theo từ khoá (tên, có hỗ trợ tiếng Việt không dấu bên BE)
  static Future<List<FoodItem>> searchFoods(String query) async {
    final idToken = await _getIdToken();
    final uri = Uri.parse('$_baseUrl?query=${Uri.encodeComponent(query)}');
    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    });
    if (response.statusCode == 200) {
      final List<dynamic> rawList = jsonDecode(response.body);
      return rawList.map((e) => FoodItem.fromJson(e)).toList();
    } else {
      _handleError(response, defaultMsg: 'Lỗi khi tìm kiếm món ăn');
    }
    throw Exception('Unexpected error');
  }

  /// Lấy danh sách món tự tạo (bao gồm custom food và recipe)
  static Future<List<FoodItem>> getMyFoods({int limit = 20}) async {
    final idToken = await _getIdToken();
    final uri = Uri.parse('$_baseUrl/my-foods?limit=$limit');
    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    });
    if (response.statusCode == 200) {
      final List<dynamic> rawList = jsonDecode(response.body);
      return rawList.map((e) => FoodItem.fromJson(e)).toList();
    } else {
      _handleError(response, defaultMsg: 'Lỗi khi tải danh sách món của bạn');
    }
    throw Exception('Unexpected error');
  }

  /// Tạo món ăn thủ công (custom food, KHÔNG PHẢI RECIPE)
  static Future<void> createCustomFood({
    required String name,
    required String unit,
    required double calories,
    required double protein,
    required double fat,
    required double carbs,
    File? image,
  }) async {
    final idToken = await _getIdToken();
    var uri = Uri.parse('$_baseUrl/create');
    var request = http.MultipartRequest('POST', uri)
      ..fields['name'] = name
      ..fields['serving_unit'] = unit
      ..fields['serving_size'] = '100' // fix 100g/ml cho custom food
      ..fields['calories'] = calories.toString()
      ..fields['protein'] = protein.toString()
      ..fields['fat'] = fat.toString()
      ..fields['carbs'] = carbs.toString()
      ..fields['is_custom'] = 'true'
      ..fields['is_recipe'] = 'false'
      ..headers['Authorization'] = 'Bearer $idToken';

    // Thêm ảnh nếu có
    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
    }

    final streamedResponse = await request.send();
    final resp = await http.Response.fromStream(streamedResponse);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      _handleError(resp, defaultMsg: 'Tạo thực phẩm thất bại');
    }
  }

  /// Cập nhật custom food (theo foodId)
  static Future<void> updateCustomFood({
    required int foodId,
    required String name,
    required String unit,
    required double calories,
    required double protein,
    required double fat,
    required double carbs,
    File? image,
  }) async {
    final idToken = await _getIdToken();
    var uri = Uri.parse('$_baseUrl/$foodId/update');
    var request = http.MultipartRequest('PUT', uri)
      ..fields['name'] = name
      ..fields['serving_unit'] = unit
      ..fields['serving_size'] = '100'
      ..fields['calories'] = calories.toString()
      ..fields['protein'] = protein.toString()
      ..fields['fat'] = fat.toString()
      ..fields['carbs'] = carbs.toString()
      ..headers['Authorization'] = 'Bearer $idToken';

    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
    }

    final streamedResponse = await request.send();
    final resp = await http.Response.fromStream(streamedResponse);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      _handleError(resp, defaultMsg: 'Cập nhật thực phẩm thất bại');
    }
  }

  /// Xoá custom food (của user tự tạo)
  static Future<void> deleteCustomFood(int foodId) async {
    final idToken = await _getIdToken();
    final uri = Uri.parse('$_baseUrl/$foodId/delete');
    final response = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _handleError(response, defaultMsg: 'Xoá thực phẩm thất bại');
    }
  }

  /// Tạo món ăn kiểu công thức (recipe)
  /// ingredients = list chứa các ingredient {food_item_id, quantity, unit}
  static Future<void> createRecipe({
    required String name,
    required double servingSize,
    required String unit,
    required List<Map<String, dynamic>> ingredients,
    File? image,
  }) async {
    final idToken = await _getIdToken();
    final uri = Uri.parse('$_baseUrl/recipes');
    final request = http.MultipartRequest('POST', uri)
      ..fields['name'] = name
      ..fields['serving_size'] = servingSize.toString()
      ..fields['serving_unit'] = unit
      ..fields['ingredients'] = jsonEncode(ingredients)
      ..headers['Authorization'] = 'Bearer $idToken';

    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
    }

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      _handleError(resp, defaultMsg: 'Tạo công thức món ăn thất bại');
    }
  }

  static Future<void> updateRecipe({
    required int foodItemId,
    required String name,
    required double servingSize,
    required String unit,
    required List<Map<String, dynamic>> ingredients,
    File? image,
  }) async {
    final idToken = await _getIdToken();
    final uri = Uri.parse('$_baseUrl/recipes/$foodItemId');
    final request = http.MultipartRequest('PUT', uri)
      ..fields['name'] = name
      ..fields['serving_size'] = servingSize.toString()
      ..fields['serving_unit'] = unit
      ..fields['ingredients'] = jsonEncode(ingredients)
      ..headers['Authorization'] = 'Bearer $idToken';

    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
    }

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      _handleError(resp, defaultMsg: 'Cập nhật công thức món ăn thất bại');
    }
  }

  static Future<List<IngredientEntry>> getIngredientsForRecipe(
      int recipeId) async {
    final idToken = await _getIdToken();
    final uri = Uri.parse('$_baseUrl/recipes/$recipeId/ingredients');
    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    });

    if (response.statusCode == 200) {
      final List<dynamic> rawList = jsonDecode(response.body);
      return rawList.map((e) => IngredientEntry.fromJson(e)).toList();
    } else {
      _handleError(response, defaultMsg: 'Lỗi khi tải nguyên liệu công thức');
    }
    throw Exception('Unexpected error');
  }

  static Future<List<FoodItem>> getFavoriteFoods(List<int> favoriteIds) async {
    final idToken = await _getIdToken();
    final uri = Uri.parse('$_baseUrl/favorites');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({'favorite_ids': favoriteIds}),
    );
    if (response.statusCode == 200) {
      final List<dynamic> rawList = jsonDecode(response.body);
      return rawList.map((e) => FoodItem.fromJson(e)).toList();
    } else {
      _handleError(response, defaultMsg: 'Lỗi khi tải danh sách yêu thích');
    }
    throw Exception('Unexpected error');
  }
}
