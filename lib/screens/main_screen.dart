import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/content_models.dart';
import '../theme.dart';
import '../widgets/category_sidebar.dart';
import '../widgets/channel_tile.dart';
import '../widgets/media_card.dart';
import 'login_screen.dart';
import 'player_screen.dart';
import 'series_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  bool _searchVisible = false;
  late final AnimationController _tabCtrl;
  late final Animation<double> _tabAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _tabCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _tabAnim = CurvedAnimation(parent: _tabCtrl, curve: Curves.easeOut);
    _tabCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadLiveCategories();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _switchTab(ContentTab tab) {
    final provider = context.read<AppProvider>();
    if (provider.currentTab == tab) return;
    provider.setTab(tab);
    _tabCtrl.forward(from: 0);
    _searchCtrl.clear();
    setState(() => _searchVisible = false);
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تسجيل الخروج',
            style: TextStyle(color: Colors.white)),
        content: const Text('هل تريد تسجيل الخروج من حسابك؟',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.liveColor),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<AppProvider>().logout();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  void _openPlayer(String url, String title,
      {bool isLive = false, String? cover}) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => PlayerScreen(
            url: url, title: title, isLive: isLive, cover: cover),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: Row(
              children: [
                _buildSidebar(),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final provider = context.watch<AppProvider>();
    return Container(
      height: 56,
      color: AppTheme.bgSidebar,
      child: Row(
        children: [
          const SizedBox(width: 16),
          // Logo
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
            ),
            child: const Center(
              child: Text('K',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'ELKHALFY',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 24),
          // Tabs
          _TabBtn(
            label: 'LIVE TV',
            icon: Icons.live_tv_rounded,
            selected: provider.currentTab == ContentTab.live,
            onTap: () => _switchTab(ContentTab.live),
          ),
          const SizedBox(width: 4),
          _TabBtn(
            label: 'Movies',
            icon: Icons.movie_rounded,
            selected: provider.currentTab == ContentTab.movies,
            onTap: () => _switchTab(ContentTab.movies),
          ),
          const SizedBox(width: 4),
          _TabBtn(
            label: 'Series',
            icon: Icons.video_library_rounded,
            selected: provider.currentTab == ContentTab.series,
            onTap: () => _switchTab(ContentTab.series),
          ),
          const Spacer(),
          // Search
          if (_searchVisible)
            SizedBox(
              width: 200,
              height: 36,
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'بحث...',
                  hintStyle:
                      const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  filled: true,
                  fillColor: AppTheme.bgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
                onChanged: (q) => context.read<AppProvider>().setSearch(q),
              ),
            ),
          IconButton(
            icon: Icon(
              _searchVisible ? Icons.close : Icons.search_rounded,
              color: Colors.white70,
            ),
            onPressed: () {
              setState(() {
                _searchVisible = !_searchVisible;
                if (!_searchVisible) {
                  _searchCtrl.clear();
                  context.read<AppProvider>().setSearch('');
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white54),
            onPressed: _logout,
            tooltip: 'تسجيل الخروج',
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final provider = context.watch<AppProvider>();
    List<Category> cats;
    String selected;
    void Function(String) onSelect;

    switch (provider.currentTab) {
      case ContentTab.live:
        cats = provider.liveCategories;
        selected = provider.selectedLiveCategoryId;
        onSelect = provider.selectLiveCategory;
      case ContentTab.movies:
        cats = provider.movieCategories;
        selected = provider.selectedMovieCategoryId;
        onSelect = provider.selectMovieCategory;
      case ContentTab.series:
        cats = provider.seriesCategories;
        selected = provider.selectedSeriesCategoryId;
        onSelect = provider.selectSeriesCategory;
    }

    return CategorySidebar(
      categories: cats,
      selectedId: selected,
      isLoading: provider.isCategoryLoading,
      onSelect: onSelect,
    );
  }

  Widget _buildContent() {
    final provider = context.watch<AppProvider>();
    return FadeTransition(
      opacity: _tabAnim,
      child: switch (provider.currentTab) {
        ContentTab.live => _buildLiveContent(provider),
        ContentTab.movies => _buildMoviesContent(provider),
        ContentTab.series => _buildSeriesContent(provider),
      },
    );
  }

  Widget _buildLiveContent(AppProvider provider) {
    if (provider.isCategoryLoading) return _buildLoader();
    final channels = provider.filteredChannels;
    if (channels.isEmpty) return _buildEmpty('لا توجد قنوات');
    return ListView.builder(
      itemCount: channels.length,
      itemBuilder: (ctx, i) {
        final ch = channels[i];
        return ChannelTile(
          channel: ch,
          isFav: provider.favChannels.contains(ch.id),
          onTap: () => _openPlayer(ch.streamUrl, ch.name,
              isLive: true, cover: ch.logo),
          onFav: () => provider.toggleFavChannel(ch.id),
        );
      },
    );
  }

  Widget _buildMoviesContent(AppProvider provider) {
    if (provider.isCategoryLoading) return _buildLoader();
    if (provider.isLoading) return _buildLoader();
    final movies = provider.filteredMovies;
    if (movies.isEmpty) return _buildEmpty('لا توجد أفلام');
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 2 / 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: movies.length,
      itemBuilder: (ctx, i) {
        final m = movies[i];
        return MediaCard(
          title: m.name,
          cover: m.cover,
          isFav: provider.favMovies.contains(m.id),
          onTap: () => _openPlayer(m.streamUrl, m.name, cover: m.cover),
          onFav: () => provider.toggleFavMovie(m.id),
          badge: m.year.isNotEmpty ? m.year : null,
        );
      },
    );
  }

  Widget _buildSeriesContent(AppProvider provider) {
    if (provider.isCategoryLoading) return _buildLoader();
    if (provider.isLoading) return _buildLoader();
    final series = provider.filteredSeries;
    if (series.isEmpty) return _buildEmpty('لا توجد مسلسلات');
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 2 / 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: series.length,
      itemBuilder: (ctx, i) {
        final s = series[i];
        return MediaCard(
          title: s.name,
          cover: s.cover,
          isFav: provider.favSeries.contains(s.id),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SeriesScreen(series: s),
            ),
          ),
          onFav: () => provider.toggleFavSeries(s.id),
          badge: 'مسلسل',
        );
      },
    );
  }

  Widget _buildLoader() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 2),
          SizedBox(height: 16),
          Text('جاري التحميل...',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildEmpty(String msg) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_rounded, color: AppTheme.textSecondary, size: 48),
          const SizedBox(height: 12),
          Text(msg,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}

// ─── Tab Button ──────────────────────────────────────────────

class _TabBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TabBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? AppTheme.primaryColor : Colors.white54),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppTheme.primaryColor : Colors.white54,
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
