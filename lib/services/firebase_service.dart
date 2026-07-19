import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/server_config.dart';

class FirebaseService {
  static const String _dbUrl =
      'https://elkhalfy-324b9-default-rtdb.firebaseio.com';

  static Future<ServerConfig?> validateCode(String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) return null;
    try {
      final uri = Uri.parse('$_dbUrl/codes/$trimmed.json');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);
      if (data == null || data is! Map) return null;
      final map = Map<String, dynamic>.from(data);
      if (map['active'] == false) return null;
      final cfg = ServerConfig.fromJson(trimmed, map);
      if (cfg.isExpired) return null;
      return cfg;
    } catch (_) {
      return null;
    }
  }
}
