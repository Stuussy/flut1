import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheManager {
  static const Duration _ttl = Duration(hours: 24);
  static const String _dataPrefix = 'compat_cache_';
  static const String _tsPrefix = 'compat_ts_';

  static String _dataKey(String email, String gameTitle) =>
      '$_dataPrefix${email}_$gameTitle';

  static String _tsKey(String email, String gameTitle) =>
      '$_tsPrefix${email}_$gameTitle';

  /// Returns cached compatibility data if it exists and is younger than 24 h.
  static Future<Map<String, dynamic>?> getCompatibility(
      String email, String gameTitle) async {
    final prefs = await SharedPreferences.getInstance();
    final tsKey = _tsKey(email, gameTitle);
    final dataKey = _dataKey(email, gameTitle);

    final timestamp = prefs.getInt(tsKey);
    if (timestamp == null) return null;

    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    if (age > _ttl.inMilliseconds) {
      await prefs.remove(dataKey);
      await prefs.remove(tsKey);
      return null;
    }

    final json = prefs.getString(dataKey);
    if (json == null) return null;

    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Saves compatibility data to cache.
  static Future<void> saveCompatibility(
      String email, String gameTitle, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dataKey(email, gameTitle), jsonEncode(data));
    await prefs.setInt(
        _tsKey(email, gameTitle), DateTime.now().millisecondsSinceEpoch);
  }

  /// Invalidates the cache for a specific game/user.
  static Future<void> clearCompatibility(
      String email, String gameTitle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dataKey(email, gameTitle));
    await prefs.remove(_tsKey(email, gameTitle));
  }
}
