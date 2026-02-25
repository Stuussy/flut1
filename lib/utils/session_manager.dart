import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyUserEmail = 'user_email';
  static const String _keyIsLoggedIn = 'is_logged_in';

  static Future<void> saveUserSession(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserEmail, email);
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserEmail);
    await prefs.setBool(_keyIsLoggedIn, false);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
