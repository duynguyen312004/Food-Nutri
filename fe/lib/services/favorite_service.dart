import 'package:shared_preferences/shared_preferences.dart';

class FavoriteService {
  static const _key = 'favorite_food_ids';
  static const maxFavorites = 50;

  static Future<List<int>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? [];
    return ids.map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toList();
  }

  static Future<bool> addFavorite(int foodId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> ids = prefs.getStringList(_key) ?? [];
    if (ids.contains(foodId.toString())) return true;
    if (ids.length >= maxFavorites) return false;
    ids.add(foodId.toString());
    await prefs.setStringList(_key, ids);
    return true;
  }

  static Future<void> removeFavorite(int foodId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> ids = prefs.getStringList(_key) ?? [];
    ids.remove(foodId.toString());
    await prefs.setStringList(_key, ids);
  }

  static Future<bool> isFavorite(int foodId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? [];
    return ids.contains(foodId.toString());
  }

  static Future<int> countFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? [];
    return ids.length;
  }
}
