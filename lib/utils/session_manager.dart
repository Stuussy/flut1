import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyUserEmail = 'user_email';

  /// Incremented whenever the user saves new PC specs.
  static final ValueNotifier<int> pcChangeCount = ValueNotifier(0);
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyAuthToken = 'auth_token';

  static Future<void> saveUserSession(String email, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyAuthToken, token);
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAuthToken);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyAuthToken);
    await prefs.setBool(_keyIsLoggedIn, false);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Call this when any API returns HTTP 401.
  /// Clears the session and navigates to the login screen.
  static Future<void> handleUnauthorized(BuildContext context) async {
    await logout();
    if (context.mounted) {
      // Import is deferred to avoid circular imports — use dynamic routing.
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }
}
