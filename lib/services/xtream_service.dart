import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/content_models.dart';
import '../models/server_config.dart';

class XtreamService {
  final ServerConfig config;
  late final String _base;

  XtreamService(this.config) {
    final url = config.url.trimRight();
    _base = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  String get _authParams =>
      'username=${config.username}&password=${config.password}';

  Future<Map<String, dynamic>?> _get(String action,
      [String extra = '']) async {
    final uri = Uri.parse(
        '$_base/player_api.php?$_authParams&action=$action$extra');
    try {
      final res = await http.get(uri, headers: {
        'User-Agent': 'Elkhalfy/1.0'
      }).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map) return Map<String, dynamic>.from(body);
      }
    } catch (_) {}
    return null;
  }

  Future<List<dynamic>> _getList(String action, [String extra = '']) async {
    final uri = Uri.parse(
        '$_base/player_api.php?$_authParams&action=$action$extra');
    try {
      final res = await http.get(uri, headers: {
        'User-Agent': 'Elkhalfy/1.0'
      }).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is List) return body;
      }
    } catch (_) {}
    return [];
  }

  Future<List<Category>> getLiveCategories() async {
    final list = await _getList('get_live_categories');
    return list
        .map((e) => Category.fromXtream(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<LiveChannel>> getLiveStreams([String? categoryId]) async {
    final extra = categoryId != null ? '&category_id=$categoryId' : '';
    final list = await _getList('get_live_streams', extra);
    return list
        .map((e) =>
            LiveChannel.fromXtream(Map<String, dynamic>.from(e), _base))
        .toList();
  }

  Future<List<Category>> getVodCategories() async {
    final list = await _getList('get_vod_categories');
    return list
        .map((e) => Category.fromXtream(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Movie>> getVodStreams([String? categoryId]) async {
    final extra = categoryId != null ? '&category_id=$categoryId' : '';
    final list = await _getList('get_vod_streams', extra);
    return list
        .map((e) => Movie.fromXtream(Map<String, dynamic>.from(e), _base))
        .toList();
  }

  Future<List<Category>> getSeriesCategories() async {
    final list = await _getList('get_series_categories');
    return list
        .map((e) => Category.fromXtream(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Series>> getSeries([String? categoryId]) async {
    final extra = categoryId != null ? '&category_id=$categoryId' : '';
    final list = await _getList('get_series', extra);
    return list
        .map((e) => Series.fromXtream(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<SeriesEpisode>> getSeriesEpisodes(String seriesId) async {
    final data = await _get('get_series_info', '&series_id=$seriesId');
    if (data == null) return [];
    final episodes = <SeriesEpisode>[];
    final seasonsData = data['episodes'];
    if (seasonsData is Map) {
      for (final seasonEntries in seasonsData.values) {
        if (seasonEntries is List) {
          for (final ep in seasonEntries) {
            if (ep is Map) {
              episodes.add(
                  SeriesEpisode.fromXtream(Map<String, dynamic>.from(ep), _base));
            }
          }
        }
      }
    }
    return episodes;
  }

  String buildLiveUrl(String streamId, [String ext = 'ts']) {
    return '$_base/live/${config.username}/${config.password}/$streamId.$ext';
  }

  String buildMovieUrl(String streamId, [String ext = 'mp4']) {
    return '$_base/movie/${config.username}/${config.password}/$streamId.$ext';
  }

  String buildSeriesUrl(String streamId, [String ext = 'mp4']) {
    return '$_base/series/${config.username}/${config.password}/$streamId.$ext';
  }
}
