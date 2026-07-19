import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../theme.dart';

class PlayerScreen extends StatefulWidget {
  final String url;
  final String title;
  final bool isLive;
  final String? cover;

  const PlayerScreen({
    super.key,
    required this.url,
    required this.title,
    this.isLive = false,
    this.cover,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  VideoPlayerController? _ctrl;
  bool _isInitializing = true;
  bool _hasError = false;
  String _errorMsg = '';
  bool _showControls = true;
  Timer? _hideTimer;
  Timer? _retryTimer;
  int _retryCount = 0;
  static const int _maxRetries = 5;
  bool _isBuffering = false;

  late final AnimationController _controlsCtrl;
  late final Animation<double> _controlsFade;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable();

    _controlsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _controlsFade =
        CurvedAnimation(parent: _controlsCtrl, curve: Curves.easeInOut);
    _controlsCtrl.forward();

    _initPlayer();
  }

  Future<void> _initPlayer() async {
    setState(() {
      _isInitializing = true;
      _hasError = false;
    });
    try {
      final uri = Uri.parse(widget.url);
      final ctrl = VideoPlayerController.networkUrl(
        uri,
        httpHeaders: const {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 11; TV) Elkhalfy/1.0',
          'Connection': 'keep-alive',
        },
      );
      await ctrl.initialize();
      if (!mounted) {
        ctrl.dispose();
        return;
      }
      _ctrl?.dispose();
      _ctrl = ctrl;
      _ctrl!.addListener(_onVideoEvent);
      _ctrl!.play();
      setState(() => _isInitializing = false);
      _startHideTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _hasError = true;
        _errorMsg = e.toString();
      });
      _scheduleRetry();
    }
  }

  void _onVideoEvent() {
    if (!mounted || _ctrl == null) return;
    final val = _ctrl!.value;
    final buffering = val.isBuffering;
    if (buffering != _isBuffering) {
      setState(() => _isBuffering = buffering);
    }
    // Auto-retry on error
    if (val.hasError && _retryCount < _maxRetries) {
      _scheduleRetry();
    }
    // Auto-reconnect if live stream stops unexpectedly
    if (widget.isLive &&
        !val.isPlaying &&
        !val.isBuffering &&
        !val.hasError &&
        val.isInitialized &&
        _retryCount < _maxRetries) {
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    if (_retryCount >= _maxRetries) return;
    _retryTimer?.cancel();
    final delay = Duration(seconds: 2 + _retryCount * 2);
    _retryTimer = Timer(delay, () {
      if (!mounted) return;
      _retryCount++;
      _initPlayer();
    });
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _showControls) {
        _controlsCtrl.reverse();
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _controlsCtrl.forward();
      _startHideTimer();
    } else {
      _controlsCtrl.reverse();
      _hideTimer?.cancel();
    }
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (!_showControls) {
      _toggleControls();
      return;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.space:
        _playPause();
      case LogicalKeyboardKey.arrowLeft:
        _seek(-10);
      case LogicalKeyboardKey.arrowRight:
        _seek(10);
      case LogicalKeyboardKey.goBack:
      case LogicalKeyboardKey.escape:
        Navigator.pop(context);
      default:
        _startHideTimer();
    }
  }

  void _playPause() {
    if (_ctrl == null) return;
    setState(() {
      if (_ctrl!.value.isPlaying) {
        _ctrl!.pause();
      } else {
        _ctrl!.play();
        _startHideTimer();
      }
    });
  }

  void _seek(int seconds) {
    if (_ctrl == null || widget.isLive) return;
    final pos = _ctrl!.value.position;
    final dur = _ctrl!.value.duration;
    final next = pos + Duration(seconds: seconds);
    final clamped = next < Duration.zero ? Duration.zero : (next > dur ? dur : next);
    _ctrl!.seekTo(clamped);
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _retryTimer?.cancel();
    _ctrl?.removeListener(_onVideoEvent);
    _ctrl?.dispose();
    _controlsCtrl.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (_, event) {
          _handleKey(event);
          return KeyEventResult.handled;
        },
        child: GestureDetector(
          onTap: _toggleControls,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video
              _buildVideoArea(),
              // Controls overlay
              if (_showControls || _isBuffering || _isInitializing || _hasError)
                FadeTransition(
                  opacity: _controlsFade,
                  child: _buildOverlay(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoArea() {
    if (_isInitializing) {
      return Stack(
        fit: StackFit.expand,
        children: [
          if (widget.cover != null && widget.cover!.isNotEmpty)
            Image.network(widget.cover!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox()),
          Container(color: Colors.black.withOpacity(0.6)),
        ],
      );
    }
    if (_hasError) {
      return const Center(
        child: Icon(Icons.wifi_off_rounded, color: Colors.white30, size: 64),
      );
    }
    if (_ctrl != null && _ctrl!.value.isInitialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: _ctrl!.value.aspectRatio,
          child: VideoPlayer(_ctrl!),
        ),
      );
    }
    return const SizedBox();
  }

  Widget _buildOverlay() {
    return Stack(
      children: [
        // Top gradient
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.85), Colors.transparent],
              ),
            ),
          ),
        ),
        // Bottom gradient
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.85), Colors.transparent],
              ),
            ),
          ),
        ),
        // Top bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildTopBar(),
        ),
        // Center
        Center(child: _buildCenter()),
        // Bottom bar
        if (!_isInitializing && !_hasError)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(),
          ),
      ],
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.isLive)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.liveColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Colors.white, size: 8),
                    SizedBox(width: 4),
                    Text('LIVE',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenter() {
    if (_isInitializing) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          const Text('جاري تحميل البث...',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          if (_retryCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('محاولة $_retryCount / $_maxRetries',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12)),
            ),
        ],
      );
    }
    if (_hasError) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppTheme.liveColor, size: 56),
          const SizedBox(height: 12),
          const Text('تعذر تشغيل البث',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            _retryCount < _maxRetries
                ? 'جاري إعادة المحاولة...'
                : 'فشل الاتصال بالبث',
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _OutlineButton(
                icon: Icons.refresh_rounded,
                label: 'إعادة المحاولة',
                onTap: () {
                  _retryCount = 0;
                  _initPlayer();
                },
              ),
              const SizedBox(width: 12),
              _OutlineButton(
                icon: Icons.arrow_back_rounded,
                label: 'رجوع',
                onTap: () => Navigator.pop(context),
              ),
            ],
          )
        ],
      );
    }
    if (_isBuffering) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
              color: AppTheme.primaryColor, strokeWidth: 3),
        ),
      );
    }
    // Play/Pause button
    if (!(_ctrl?.value.isPlaying ?? false)) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.play_arrow_rounded,
            color: Colors.white, size: 52),
      );
    }
    return const SizedBox();
  }

  Widget _buildBottomBar() {
    if (_ctrl == null || !_ctrl!.value.isInitialized) return const SizedBox();
    final duration = _ctrl!.value.duration;
    final position = _ctrl!.value.position;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.isLive)
              _ProgressBar(
                position: position,
                duration: duration,
                buffered: _ctrl!.value.buffered,
                onSeek: (d) {
                  _ctrl!.seekTo(d);
                  _startHideTimer();
                },
              ),
            Row(
              children: [
                if (!widget.isLive) ...[
                  _ControlBtn(
                    icon: Icons.replay_10_rounded,
                    onTap: () => _seek(-10),
                  ),
                  const SizedBox(width: 4),
                ],
                _ControlBtn(
                  icon: (_ctrl?.value.isPlaying ?? false)
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 36,
                  onTap: _playPause,
                ),
                if (!widget.isLive) ...[
                  const SizedBox(width: 4),
                  _ControlBtn(
                    icon: Icons.forward_10_rounded,
                    onTap: () => _seek(10),
                  ),
                ],
                const SizedBox(width: 12),
                if (!widget.isLive)
                  Text(
                    '${_formatDur(position)} / ${_formatDur(duration)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                const Spacer(),
                _ControlBtn(
                  icon: Icons.fullscreen_rounded,
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDur(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}

// ─── Helper Widgets ──────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final List<DurationRange> buffered;
  final ValueChanged<Duration> onSeek;

  const _ProgressBar({
    required this.position,
    required this.duration,
    required this.buffered,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final total = duration.inMilliseconds.toDouble();
    final pos = total > 0 ? position.inMilliseconds / total : 0.0;
    final buf = total > 0 && buffered.isNotEmpty
        ? buffered.last.end.inMilliseconds / total
        : 0.0;
    return GestureDetector(
      onTapDown: (d) {
        final w = context.size?.width ?? 1;
        final frac = (d.localPosition.dx / w).clamp(0.0, 1.0);
        onSeek(Duration(milliseconds: (frac * total).toInt()));
      },
      child: Container(
        height: 28,
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerLeft,
          children: [
            // Background
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Buffered
            FractionallySizedBox(
              widthFactor: buf.clamp(0.0, 1.0),
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white38,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // Played
            FractionallySizedBox(
              widthFactor: pos.clamp(0.0, 1.0),
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // Thumb
            Positioned(
              left: (pos * (MediaQuery.of(context).size.width - 32) - 7)
                  .clamp(0.0, double.infinity),
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _ControlBtn({required this.icon, required this.onTap, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OutlineButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
