class Category {
  final String id;
  final String name;
  int count;

  Category({required this.id, required this.name, this.count = 0});

  factory Category.fromXtream(Map<String, dynamic> json) => Category(
        id: json['category_id']?.toString() ?? '',
        name: json['category_name']?.toString() ?? '',
        count: int.tryParse(json['parent_id']?.toString() ?? '0') ?? 0,
      );
}

class LiveChannel {
  final String id;
  final String name;
  final String streamUrl;
  final String logo;
  final String categoryId;
  final int num;
  final String epgId;

  const LiveChannel({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.logo = '',
    this.categoryId = '',
    this.num = 0,
    this.epgId = '',
  });

  factory LiveChannel.fromXtream(Map<String, dynamic> j, String baseUrl) {
    final id = j['stream_id']?.toString() ?? '';
    final ext = j['container_extension']?.toString() ?? 'ts';
    final username = '';
    final password = '';
    // Extract from baseUrl
    final uri = Uri.tryParse(baseUrl);
    final parts = uri?.pathSegments ?? [];
    final user = parts.length > 1 ? parts[1] : username;
    final pass = parts.length > 2 ? parts[2] : password;
    final host = uri != null ? '${uri.scheme}://${uri.host}:${uri.port}' : baseUrl;
    final url = '$host/live/$user/$pass/$id.$ext';
    return LiveChannel(
      id: id,
      name: j['name']?.toString() ?? '',
      streamUrl: url,
      logo: j['stream_icon']?.toString() ?? '',
      categoryId: j['category_id']?.toString() ?? '',
      num: int.tryParse(j['num']?.toString() ?? '0') ?? 0,
      epgId: j['epg_channel_id']?.toString() ?? '',
    );
  }

  factory LiveChannel.fromM3U({
    required String id,
    required String name,
    required String url,
    String logo = '',
    String group = '',
  }) =>
      LiveChannel(
          id: id, name: name, streamUrl: url, logo: logo, categoryId: group);
}

class Movie {
  final String id;
  final String name;
  final String streamUrl;
  final String cover;
  final String categoryId;
  final String plot;
  final String rating;
  final String year;
  final String duration;

  const Movie({
    required this.id,
    required this.name,
    required this.streamUrl,
    this.cover = '',
    this.categoryId = '',
    this.plot = '',
    this.rating = '',
    this.year = '',
    this.duration = '',
  });

  factory Movie.fromXtream(Map<String, dynamic> j, String baseUrl) {
    final id = j['stream_id']?.toString() ?? '';
    final ext = j['container_extension']?.toString() ?? 'mp4';
    final uri = Uri.tryParse(baseUrl);
    final parts = uri?.pathSegments ?? [];
    final user = parts.length > 1 ? parts[1] : '';
    final pass = parts.length > 2 ? parts[2] : '';
    final host = uri != null ? '${uri.scheme}://${uri.host}:${uri.port}' : baseUrl;
    final url = '$host/movie/$user/$pass/$id.$ext';
    return Movie(
      id: id,
      name: j['name']?.toString() ?? '',
      streamUrl: url,
      cover: j['stream_icon']?.toString() ?? '',
      categoryId: j['category_id']?.toString() ?? '',
      plot: j['plot']?.toString() ?? '',
      rating: j['rating']?.toString() ?? '',
      year: j['year']?.toString() ?? '',
      duration: j['duration']?.toString() ?? '',
    );
  }
}

class Series {
  final String id;
  final String name;
  final String cover;
  final String categoryId;
  final String plot;
  final String rating;
  final String year;

  const Series({
    required this.id,
    required this.name,
    this.cover = '',
    this.categoryId = '',
    this.plot = '',
    this.rating = '',
    this.year = '',
  });

  factory Series.fromXtream(Map<String, dynamic> j) => Series(
        id: j['series_id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        cover: j['cover']?.toString() ?? '',
        categoryId: j['category_id']?.toString() ?? '',
        plot: j['plot']?.toString() ?? '',
        rating: j['rating']?.toString() ?? '',
        year: j['last_modified']?.toString() ?? '',
      );
}

class SeriesEpisode {
  final String id;
  final String title;
  final String streamUrl;
  final int season;
  final int episode;
  final String info;

  const SeriesEpisode({
    required this.id,
    required this.title,
    required this.streamUrl,
    this.season = 1,
    this.episode = 1,
    this.info = '',
  });

  factory SeriesEpisode.fromXtream(Map<String, dynamic> j, String baseUrl) {
    final id = j['id']?.toString() ?? '';
    final ext = j['container_extension']?.toString() ?? 'mp4';
    final uri = Uri.tryParse(baseUrl);
    final parts = uri?.pathSegments ?? [];
    final user = parts.length > 1 ? parts[1] : '';
    final pass = parts.length > 2 ? parts[2] : '';
    final host = uri != null ? '${uri.scheme}://${uri.host}:${uri.port}' : baseUrl;
    final url = '$host/series/$user/$pass/$id.$ext';
    return SeriesEpisode(
      id: id,
      title: j['title']?.toString() ?? 'الحلقة $id',
      streamUrl: url,
      season: int.tryParse(j['season']?.toString() ?? '1') ?? 1,
      episode: int.tryParse(j['episode_num']?.toString() ?? '1') ?? 1,
      info: j['info']?.toString() ?? '',
    );
  }
}

class M3UEntry {
  final String name;
  final String url;
  final String logo;
  final String group;

  const M3UEntry({
    required this.name,
    required this.url,
    this.logo = '',
    this.group = '',
  });
}
