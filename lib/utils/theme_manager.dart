import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager {
  static const String _key = 'theme_mode'; // 'dark' | 'light' | 'system'

  static final ValueNotifier<ThemeMode> notifier =
      ValueNotifier(ThemeMode.dark);

  static Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      notifier.value = _fromString(saved);
    } else {
      // migrate from old bool key
      final oldBool = prefs.getBool('is_dark_theme');
      if (oldBool != null) {
        notifier.value = oldBool ? ThemeMode.dark : ThemeMode.light;
      }
    }
  }

  static Future<void> setTheme(ThemeMode mode) async {
    notifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _toString(mode));
  }

  /// Обратная совместимость: вызывается из profile_page.dart.
  static Future<void> setDarkMode(bool isDark) =>
      setTheme(isDark ? ThemeMode.dark : ThemeMode.light);

  static bool get isDark => notifier.value == ThemeMode.dark;

  static String _toString(ThemeMode m) {
    if (m == ThemeMode.light) return 'light';
    if (m == ThemeMode.system) return 'system';
    return 'dark';
  }

  static ThemeMode _fromString(String s) {
    if (s == 'light') return ThemeMode.light;
    if (s == 'system') return ThemeMode.system;
    return ThemeMode.dark;
  }
}
