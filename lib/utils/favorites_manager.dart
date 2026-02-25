import 'package:shared_preferences/shared_preferences.dart';

class FavoritesManager {
  static const String _key = 'favorite_games';
  static const int maxFavorites = 5;

  static Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<bool> isFavorite(String gameTitle) async {
    final favorites = await getFavorites();
    return favorites.contains(gameTitle);
  }

  /// Returns true if the game was added, false if removed.
  /// Throws if maxFavorites reached and game is not in the list.
  static Future<bool> toggleFavorite(String gameTitle) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = List<String>.from(prefs.getStringList(_key) ?? []);

    if (favorites.contains(gameTitle)) {
      favorites.remove(gameTitle);
      await prefs.setStringList(_key, favorites);
      return false;
    } else {
      if (favorites.length >= maxFavorites) {
        throw Exception('Максимум $maxFavorites избранных игр');
      }
      favorites.add(gameTitle);
      await prefs.setStringList(_key, favorites);
      return true;
    }
  }

  static Future<bool> canAdd() async {
    final favorites = await getFavorites();
    return favorites.length < maxFavorites;
  }
}
