import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/content_models.dart';
import '../models/server_config.dart';

class MacService {
  final ServerConfig config;
  String _token = '';
  late final String _base;

  MacService(this.config) {
    final url = config.url.trimRight();
    _base = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  Map<String, String> get _headers => {
        'User-Agent': 'Mozilla/5.0 (QtEmbedded; U; Linux; C) AppleWebKit/533.3',
        'X-User-Agent': 'Model: MAG254; Link: WiFi',
        'Cookie': 'mac=${config.mac}; stb_lang=en; timezone=Europe/London',
        'Referer': '$_base/c/',
      };

  Future<bool> connect() async {
    try {
      final uri = Uri.parse(
          '$_base/portal.php?type=stb&action=handshake&JsHttpRequest=1-xml');
      final res =
          await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return false;
      final data = jsonDecode(res.body);
      _token = data?['js']?['token'] as String? ?? '';
      return _token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<List<Category>> getLiveCategories() async {
    try {
      final uri = Uri.parse(
          '$_base/portal.php?type=itv&action=get_genres&JsHttpRequest=1-xml');
      final headers = Map<String, String>.from(_headers);
      headers['Authorization'] = 'Bearer $_token';
      final res =
          await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body);
      final list = data?['js'] as List? ?? [];
      return list
          .map((e) => Category(
              id: e['id']?.toString() ?? '',
              name: e['title']?.toString() ?? ''))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<LiveChannel>> getLiveChannels(String categoryId) async {
    try {
      final uri = Uri.parse(
          '$_base/portal.php?type=itv&action=get_ordered_list&genre=$categoryId&JsHttpRequest=1-xml');
      final headers = Map<String, String>.from(_headers);
      headers['Authorization'] = 'Bearer $_token';
      final res =
          await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body);
      final list = data?['js']?['data'] as List? ?? [];
      return list
          .map((e) => LiveChannel(
                id: e['id']?.toString() ?? '',
                name: e['name']?.toString() ?? '',
                streamUrl: '',
                logo: e['logo']?.toString() ?? '',
                categoryId: categoryId,
                num: int.tryParse(e['number']?.toString() ?? '0') ?? 0,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<String> createLink(String cmd) async {
    try {
      final encoded = Uri.encodeComponent(cmd);
      final uri = Uri.parse(
          '$_base/portal.php?type=itv&action=create_link&cmd=$encoded&JsHttpRequest=1-xml');
      final headers = Map<String, String>.from(_headers);
      headers['Authorization'] = 'Bearer $_token';
      final res =
          await http.get(uri, headers: headers).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return '';
      final data = jsonDecode(res.body);
      final cmd2 = data?['js']?['cmd'] as String? ?? '';
      // cmd format: "ffmpeg <url>" or just url
      final parts = cmd2.split(' ');
      return parts.last;
    } catch (_) {
      return '';
    }
  }
}
