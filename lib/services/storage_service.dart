import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Activation Code
  static String? getActivationCode() => _prefs.getString('activation_code');
  static Future<void> saveActivationCode(String code) =>
      _prefs.setString('activation_code', code);
  static Future<void> clearActivationCode() =>
      _prefs.remove('activation_code');

  // Favorites
  static List<String> getFavoriteChannels() =>
      _prefs.getStringList('fav_channels') ?? [];
  static Future<void> saveFavoriteChannels(List<String> ids) =>
      _prefs.setStringList('fav_channels', ids);

  static List<String> getFavoriteMovies() =>
      _prefs.getStringList('fav_movies') ?? [];
  static Future<void> saveFavoriteMovies(List<String> ids) =>
      _prefs.setStringList('fav_movies', ids);

  static List<String> getFavoriteSeries() =>
      _prefs.getStringList('fav_series') ?? [];
  static Future<void> saveFavoriteSeries(List<String> ids) =>
      _prefs.setStringList('fav_series', ids);

  // Last watched
  static String? getLastChannelId() => _prefs.getString('last_channel');
  static Future<void> saveLastChannelId(String id) =>
      _prefs.setString('last_channel', id);
}
