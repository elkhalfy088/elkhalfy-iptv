import 'package:http/http.dart' as http;
import '../models/content_models.dart';

class M3UService {
  final String url;

  M3UService(this.url);

  Future<List<M3UEntry>> fetchEntries() async {
    try {
      final res = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'Elkhalfy/1.0'})
          .timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) return [];
      return _parse(res.body);
    } catch (_) {
      return [];
    }
  }

  List<M3UEntry> _parse(String content) {
    final entries = <M3UEntry>[];
    final lines = content.split('\n');
    String name = '';
    String logo = '';
    String group = '';

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.startsWith('#EXTINF')) {
        name = _attr(line, 'tvg-name') ??
            _attr(line, 'tvg-id') ??
            line.split(',').last.trim();
        logo = _attr(line, 'tvg-logo') ?? '';
        group = _attr(line, 'group-title') ?? 'عام';
      } else if (line.isNotEmpty && !line.startsWith('#') && name.isNotEmpty) {
        entries.add(M3UEntry(name: name, url: line, logo: logo, group: group));
        name = '';
        logo = '';
        group = '';
      }
    }
    return entries;
  }

  String? _attr(String line, String attr) {
    final regex = RegExp('$attr="([^"]*)"');
    final match = regex.firstMatch(line);
    return match?.group(1);
  }

  List<Category> extractCategories(List<M3UEntry> entries) {
    final groups = <String>{};
    for (final e in entries) {
      if (e.group.isNotEmpty) groups.add(e.group);
    }
    return groups
        .map((g) => Category(
            id: g,
            name: g,
            count: entries.where((e) => e.group == g).length))
        .toList();
  }

  List<LiveChannel> toChannels(List<M3UEntry> entries, [String? group]) {
    final filtered =
        group == null ? entries : entries.where((e) => e.group == group).toList();
    return filtered
        .asMap()
        .entries
        .map((me) => LiveChannel.fromM3U(
              id: '${me.key}',
              name: me.value.name,
              url: me.value.url,
              logo: me.value.logo,
              group: me.value.group,
            ))
        .toList();
  }
}
