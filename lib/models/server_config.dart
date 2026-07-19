enum ServerType { xtream, m3u, mac }

class ServerConfig {
  final String code;
  final ServerType type;
  final String url;
  final String username;
  final String password;
  final String mac;
  final String expiry;
  final bool active;
  final String label;

  const ServerConfig({
    required this.code,
    required this.type,
    required this.url,
    this.username = '',
    this.password = '',
    this.mac = '',
    this.expiry = '',
    this.active = true,
    this.label = '',
  });

  bool get isExpired {
    if (expiry.isEmpty) return false;
    try {
      final exp = DateTime.parse(expiry);
      return DateTime.now().isAfter(exp);
    } catch (_) {
      return false;
    }
  }

  factory ServerConfig.fromJson(String code, Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'xtream';
    final type = typeStr == 'm3u'
        ? ServerType.m3u
        : typeStr == 'mac'
            ? ServerType.mac
            : ServerType.xtream;
    return ServerConfig(
      code: code,
      type: type,
      url: json['url'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      mac: json['mac'] as String? ?? '',
      expiry: json['expiry'] as String? ?? '',
      active: json['active'] as bool? ?? true,
      label: json['label'] as String? ?? '',
    );
  }
}
