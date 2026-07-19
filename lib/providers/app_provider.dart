import 'package:flutter/material.dart';
import '../models/content_models.dart';
import '../models/server_config.dart';
import '../services/firebase_service.dart';
import '../services/m3u_service.dart';
import '../services/mac_service.dart';
import '../services/xtream_service.dart';
import '../services/storage_service.dart';

enum ContentTab { live, movies, series }

class AppProvider extends ChangeNotifier {
  ServerConfig? serverConfig;
  XtreamService? _xtream;
  M3UService? _m3u;
  MacService? _mac;
  List<M3UEntry> _m3uCache = [];

  bool isLoading = false;
  bool isCategoryLoading = false;
  String? errorMessage;

  ContentTab currentTab = ContentTab.live;

  List<Category> liveCategories = [];
  List<LiveChannel> liveChannels = [];
  String selectedLiveCategoryId = 'all';

  List<Category> movieCategories = [];
  List<Movie> movies = [];
  String selectedMovieCategoryId = 'all';

  List<Category> seriesCategories = [];
  List<Series> seriesList = [];
  String selectedSeriesCategoryId = 'all';

  String searchQuery = '';
  Set<String> favChannels = {};
  Set<String> favMovies = {};
  Set<String> favSeries = {};

  AppProvider() {
    favChannels = Set.from(StorageService.getFavoriteChannels());
    favMovies = Set.from(StorageService.getFavoriteMovies());
    favSeries = Set.from(StorageService.getFavoriteSeries());
  }

  // ─── Activation ────────────────────────────────────────────

  Future<bool> loadFromSavedCode(String code) async {
    try {
      final cfg = await FirebaseService.validateCode(code);
      if (cfg == null) return false;
      serverConfig = cfg;
      _initService();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> activate(String code) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final cfg = await FirebaseService.validateCode(code);
      if (cfg == null) {
        errorMessage = 'كود التفعيل غير صحيح أو منتهي الصلاحية';
        isLoading = false;
        notifyListeners();
        return errorMessage;
      }
      serverConfig = cfg;
      await StorageService.saveActivationCode(code);
      _initService();
      isLoading = false;
      notifyListeners();
      return null;
    } catch (_) {
      errorMessage = 'حدث خطأ في الاتصال، تحقق من الإنترنت';
      isLoading = false;
      notifyListeners();
      return errorMessage;
    }
  }

  void _initService() {
    if (serverConfig == null) return;
    _xtream = null;
    _m3u = null;
    _mac = null;
    _m3uCache = [];
    switch (serverConfig!.type) {
      case ServerType.xtream:
        _xtream = XtreamService(serverConfig!);
      case ServerType.m3u:
        _m3u = M3UService(serverConfig!.url);
      case ServerType.mac:
        _mac = MacService(serverConfig!);
    }
  }

  // ─── Tab Navigation ────────────────────────────────────────

  void setTab(ContentTab tab) {
    if (currentTab == tab) return;
    currentTab = tab;
    searchQuery = '';
    notifyListeners();
    switch (tab) {
      case ContentTab.live:
        if (liveCategories.isEmpty) loadLiveCategories();
      case ContentTab.movies:
        if (movieCategories.isEmpty) loadMovieCategories();
      case ContentTab.series:
        if (seriesCategories.isEmpty) loadSeriesCategories();
    }
  }

  // ─── Live TV ────────────────────────────────────────────────

  Future<void> loadLiveCategories() async {
    isCategoryLoading = true;
    notifyListeners();
    try {
      if (_xtream != null) {
        liveCategories = await _xtream!.getLiveCategories();
        liveChannels = await _xtream!.getLiveStreams();
      } else if (_m3u != null) {
        _m3uCache = await _m3u!.fetchEntries();
        liveCategories = _m3u!.extractCategories(_m3uCache);
        liveChannels = _m3u!.toChannels(_m3uCache);
      } else if (_mac != null) {
        await _mac!.connect();
        liveCategories = await _mac!.getLiveCategories();
        if (liveCategories.isNotEmpty) {
          liveChannels = await _mac!.getLiveChannels(liveCategories.first.id);
        }
      }
      selectedLiveCategoryId = 'all';
    } catch (_) {}
    isCategoryLoading = false;
    notifyListeners();
  }

  Future<void> selectLiveCategory(String categoryId) async {
    if (selectedLiveCategoryId == categoryId) return;
    selectedLiveCategoryId = categoryId;
    searchQuery = '';
    isLoading = true;
    notifyListeners();
    try {
      if (_xtream != null) {
        final id = categoryId == 'all' ? null : categoryId;
        liveChannels = await _xtream!.getLiveStreams(id);
      } else if (_m3u != null) {
        final group = categoryId == 'all' ? null : categoryId;
        liveChannels = _m3u!.toChannels(_m3uCache, group);
      } else if (_mac != null) {
        liveChannels = await _mac!.getLiveChannels(categoryId);
      }
    } catch (_) {}
    isLoading = false;
    notifyListeners();
  }

  // ─── Movies ────────────────────────────────────────────────

  Future<void> loadMovieCategories() async {
    isCategoryLoading = true;
    notifyListeners();
    try {
      if (_xtream != null) {
        movieCategories = await _xtream!.getVodCategories();
        movies = await _xtream!.getVodStreams();
      }
    } catch (_) {}
    selectedMovieCategoryId = 'all';
    isCategoryLoading = false;
    notifyListeners();
  }

  Future<void> selectMovieCategory(String categoryId) async {
    if (selectedMovieCategoryId == categoryId) return;
    selectedMovieCategoryId = categoryId;
    searchQuery = '';
    isLoading = true;
    notifyListeners();
    try {
      if (_xtream != null) {
        final id = categoryId == 'all' ? null : categoryId;
        movies = await _xtream!.getVodStreams(id);
      }
    } catch (_) {}
    isLoading = false;
    notifyListeners();
  }

  // ─── Series ────────────────────────────────────────────────

  Future<void> loadSeriesCategories() async {
    isCategoryLoading = true;
    notifyListeners();
    try {
      if (_xtream != null) {
        seriesCategories = await _xtream!.getSeriesCategories();
        seriesList = await _xtream!.getSeries();
      }
    } catch (_) {}
    selectedSeriesCategoryId = 'all';
    isCategoryLoading = false;
    notifyListeners();
  }

  Future<void> selectSeriesCategory(String categoryId) async {
    if (selectedSeriesCategoryId == categoryId) return;
    selectedSeriesCategoryId = categoryId;
    searchQuery = '';
    isLoading = true;
    notifyListeners();
    try {
      if (_xtream != null) {
        final id = categoryId == 'all' ? null : categoryId;
        seriesList = await _xtream!.getSeries(id);
      }
    } catch (_) {}
    isLoading = false;
    notifyListeners();
  }

  Future<List<SeriesEpisode>> loadSeriesEpisodes(String seriesId) async {
    if (_xtream != null) {
      return await _xtream!.getSeriesEpisodes(seriesId);
    }
    return [];
  }

  // ─── MAC stream URL ────────────────────────────────────────

  Future<String> getMacStreamUrl(String cmd) async {
    if (_mac == null) return '';
    return await _mac!.createLink(cmd);
  }

  // ─── Favorites ─────────────────────────────────────────────

  void toggleFavChannel(String id) {
    if (favChannels.contains(id)) {
      favChannels.remove(id);
    } else {
      favChannels.add(id);
    }
    StorageService.saveFavoriteChannels(favChannels.toList());
    notifyListeners();
  }

  void toggleFavMovie(String id) {
    if (favMovies.contains(id)) {
      favMovies.remove(id);
    } else {
      favMovies.add(id);
    }
    StorageService.saveFavoriteMovies(favMovies.toList());
    notifyListeners();
  }

  void toggleFavSeries(String id) {
    if (favSeries.contains(id)) {
      favSeries.remove(id);
    } else {
      favSeries.add(id);
    }
    StorageService.saveFavoriteSeries(favSeries.toList());
    notifyListeners();
  }

  // ─── Search ────────────────────────────────────────────────

  void setSearch(String q) {
    searchQuery = q;
    notifyListeners();
  }

  List<LiveChannel> get filteredChannels {
    if (searchQuery.isEmpty) return liveChannels;
    final q = searchQuery.toLowerCase();
    return liveChannels.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  List<Movie> get filteredMovies {
    if (searchQuery.isEmpty) return movies;
    final q = searchQuery.toLowerCase();
    return movies.where((m) => m.name.toLowerCase().contains(q)).toList();
  }

  List<Series> get filteredSeries {
    if (searchQuery.isEmpty) return seriesList;
    final q = searchQuery.toLowerCase();
    return seriesList.where((s) => s.name.toLowerCase().contains(q)).toList();
  }

  // ─── Logout ────────────────────────────────────────────────

  Future<void> logout() async {
    await StorageService.clearActivationCode();
    serverConfig = null;
    _xtream = null;
    _m3u = null;
    _mac = null;
    _m3uCache = [];
    liveChannels = [];
    movies = [];
    seriesList = [];
    liveCategories = [];
    movieCategories = [];
    seriesCategories = [];
    searchQuery = '';
    currentTab = ContentTab.live;
    notifyListeners();
  }
}
