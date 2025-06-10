import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorite_model.dart';
import '../utils/hive_box.dart';

class FavoriteService {
  static const String _userIdKey = 'current_user_id';

  Box<FavoriteQuest> get _box => Hive.box<FavoriteQuest>(HiveBox.favorites);

  Future<void> addFavorite(String questId, String userId, String title) async {
    final favorite = FavoriteQuest(
      questId: questId,
      userId: userId,
      title: title,
      addedAt: DateTime.now(),
    );

    await _box.put('${userId}_$questId', favorite);
    await _saveUserIdToSharedPrefs(userId);
  }

  Future<void> removeFavorite(String questId, String userId) async {
    await _box.delete('${userId}_$questId');
  }

  Future<List<FavoriteQuest>> getFavoritesByUserId(String userId) async {
    return _box.values.where((fav) => fav.userId == userId).toList();
  }

  Future<bool> isFavorite(String questId, String userId) async {
    return _box.containsKey('${userId}_$questId');
  }

  Future<void> _saveUserIdToSharedPrefs(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  Future<String?> getUserIdFromSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);

    await _box.clear();
  }
}
