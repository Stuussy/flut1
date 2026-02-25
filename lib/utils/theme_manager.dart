import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager {
  static const String _key = 'is_dark_theme';

  static final ValueNotifier<ThemeMode> notifier =
      ValueNotifier(ThemeMode.dark);

  static Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_key) ?? true;
    notifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> setDarkMode(bool isDark) async {
    notifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, isDark);
  }

  static bool get isDark => notifier.value == ThemeMode.dark;
}
