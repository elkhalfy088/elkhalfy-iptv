import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/content_models.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import 'player_screen.dart';

class SeriesScreen extends StatefulWidget {
  final Series series;
  const SeriesScreen({super.key, required this.series});

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  List<SeriesEpisode> _episodes = [];
  bool _loading = true;
  int _selectedSeason = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final eps =
        await context.read<AppProvider>().loadSeriesEpisodes(widget.series.id);
    if (mounted) {
      setState(() {
        _episodes = eps;
        _loading = false;
        if (eps.isNotEmpty) _selectedSeason = eps.first.season;
      });
    }
  }

  List<int> get _seasons =>
      _episodes.map((e) => e.season).toSet().toList()..sort();

  List<SeriesEpisode> get _currentEps =>
      _episodes.where((e) => e.season == _selectedSeason).toList()
        ..sort((a, b) => a.episode.compareTo(b.episode));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: Row(
        children: [
          // Cover + info
          _buildInfo(),
          // Episodes
          Expanded(child: _buildEpisodes()),
        ],
      ),
    );
  }

  Widget _buildInfo() {
    final s = widget.series;
    return Container(
      width: 260,
      color: AppTheme.bgSidebar,
      child: Column(
        children: [
          // Back
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text('رجوع',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          // Cover
          if (s.cover.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: s.cover,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 160,
                    color: AppTheme.bgCard,
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryColor, strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 160,
                    color: AppTheme.bgCard,
                    child: const Icon(Icons.movie_rounded,
                        color: AppTheme.textSecondary, size: 40),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(s.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
          ),
          if (s.rating.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded,
                      color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(s.rating,
                      style: const TextStyle(
                          color: Colors.amber, fontSize: 13)),
                ],
              ),
            ),
          const SizedBox(height: 8),
          if (s.plot.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(s.plot,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
            ),
          const Spacer(),
          // Season selector
          if (_seasons.length > 1) ...[
            const Divider(color: AppTheme.dividerColor),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButtonFormField<int>(
                value: _selectedSeason,
                dropdownColor: AppTheme.bgCard,
                decoration: InputDecoration(
                  labelText: 'الموسم',
                  labelStyle:
                      const TextStyle(color: AppTheme.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppTheme.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppTheme.dividerColor),
                  ),
                  filled: true,
                  fillColor: AppTheme.bgColor,
                ),
                items: _seasons
                    .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text('الموسم $s',
                            style:
                                const TextStyle(color: Colors.white))))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedSeason = v);
                },
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildEpisodes() {
    if (_loading) {
      return const Center(
        child:
            CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }
    final eps = _currentEps;
    if (eps.isEmpty) {
      return const Center(
        child: Text('لا توجد حلقات',
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('الحلقات (${eps.length})',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: eps.length,
            separatorBuilder: (_, __) =>
                const Divider(color: AppTheme.dividerColor, height: 1),
            itemBuilder: (ctx, i) {
              final ep = eps[i];
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Text(
                      '${ep.episode}',
                      style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ),
                ),
                title: Text(ep.title,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14)),
                subtitle: Text(
                    'الموسم ${ep.season} - الحلقة ${ep.episode}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11)),
                trailing: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 20),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlayerScreen(
                      url: ep.streamUrl,
                      title: '${widget.series.name} - ${ep.title}',
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
