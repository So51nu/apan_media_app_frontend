import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import '../service/api_service.dart';

class ReelsPlayerItem extends StatefulWidget {
  final Map<String, dynamic> video;
  final void Function(Map<String, dynamic> updatedVideo) onUpdateFromServer;

  const ReelsPlayerItem({
    super.key,
    required this.video,
    required this.onUpdateFromServer,
  });

  @override
  State<ReelsPlayerItem> createState() => _ReelsPlayerItemState();
}

class _ReelsPlayerItemState extends State<ReelsPlayerItem>
    with AutomaticKeepAliveClientMixin {
  late final VideoPlayerController _c;

  bool _ui = true;
  Timer? _hide;
  Timer? _progressTimer;

  int get id => widget.video["id"] as int;
  String get title => (widget.video["title"] ?? "").toString();
  String get url => (widget.video["video_url"] ?? "").toString();

  int get myLike => (widget.video["my_like_status"] ?? 0) as int; // -1,0,1
  bool get mySaved => (widget.video["my_saved"] ?? false) as bool;
  bool get myDownloaded => (widget.video["my_downloaded"] ?? false) as bool;
  int get lastPosMs => (widget.video["my_last_position_ms"] ?? 0) as int;

  @override
  void initState() {
    super.initState();

    _c = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) async {
        if (!mounted) return;
        setState(() {});
        _c.setLooping(true);

        // ✅ resume from last position
        if (lastPosMs > 0) {
          await _c.seekTo(Duration(milliseconds: lastPosMs));
        }

        _c.play();
        _autoHide();
        _startProgressSync();
      });
  }

  @override
  void dispose() {
    _hide?.cancel();
    _progressTimer?.cancel();
    _c.dispose();
    super.dispose();
  }

  void _autoHide() {
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _ui = false);
    });
  }

  void _toggleUi() {
    setState(() => _ui = !_ui);
    if (_ui) _autoHide();
  }

  void _playPause() {
    if (!_c.value.isInitialized) return;
    setState(() {
      _c.value.isPlaying ? _c.pause() : _c.play();
      _ui = true;
    });
    _autoHide();
  }

  void _startProgressSync() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!_c.value.isInitialized) return;
      final ms = _c.value.position.inMilliseconds;
      await ApiService.react(videoId: id, lastPositionMs: ms);
    });
  }

  Future<void> _setLike(int likeStatus) async {
    // ✅ likeStatus: -1/0/1
    final updated = await ApiService.react(videoId: id, likeStatus: likeStatus);
    if (updated != null) widget.onUpdateFromServer(updated);
    _autoHide();
  }

  Future<void> _toggleSave() async {
    final updated = await ApiService.react(videoId: id, isSaved: !mySaved);
    if (updated != null) widget.onUpdateFromServer(updated);
    _autoHide();
  }

  Future<void> _downloadMark() async {
    // ✅ backend me downloaded flag store
    final updated = await ApiService.react(videoId: id, isDownloaded: true);
    if (updated != null) widget.onUpdateFromServer(updated);
    _autoHide();
  }

  Future<void> _share() async {
    await Share.share(url, subject: title);
    final updated = await ApiService.react(videoId: id, shareIncrement: true);
    if (updated != null) widget.onUpdateFromServer(updated);
    _autoHide();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final init = _c.value.isInitialized;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleUi,
      child: Stack(
        children: [
          // ✅ fullscreen reels cover
          Positioned.fill(
            child: init
                ? FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _c.value.size.width,
                height: _c.value.size.height,
                child: VideoPlayer(_c),
              ),
            )
                : const Center(child: CircularProgressIndicator()),
          ),

          // top title
          Positioned(
            left: 14,
            right: 14,
            top: MediaQuery.of(context).padding.top + 10,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                )
              ],
            ),
          ),

          // center play/pause
          if (_ui && init)
            Positioned.fill(
              child: Center(
                child: InkWell(
                  onTap: _playPause,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Icon(
                      _c.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
              ),
            ),

          // right actions
          Positioned(
            right: 10,
            bottom: 110,
            child: Column(
              children: [
                _Action(
                  icon: myLike == 1 ? Icons.thumb_up : Icons.thumb_up_outlined,
                  label: "Like",
                  active: myLike == 1,
                  onTap: () => _setLike(myLike == 1 ? 0 : 1),
                ),
                const SizedBox(height: 14),
                _Action(
                  icon: myLike == -1 ? Icons.thumb_down : Icons.thumb_down_outlined,
                  label: "Unlike",
                  active: myLike == -1,
                  onTap: () => _setLike(myLike == -1 ? 0 : -1),
                ),
                const SizedBox(height: 14),
                _Action(icon: Icons.share_outlined, label: "Share", onTap: _share),
                const SizedBox(height: 14),
                _Action(
                  icon: mySaved ? Icons.bookmark : Icons.bookmark_border,
                  label: "Save",
                  active: mySaved,
                  onTap: _toggleSave,
                ),
                const SizedBox(height: 14),
                _Action(
                  icon: myDownloaded ? Icons.download_done : Icons.download_outlined,
                  label: "Download",
                  active: myDownloaded,
                  onTap: _downloadMark,
                ),
              ],
            ),
          ),

          // progress bar
          if (_ui && init)
            Positioned(
              left: 12,
              right: 12,
              bottom: 20,
              child: VideoProgressIndicator(
                _c,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: Colors.redAccent,
                  bufferedColor: Colors.white30,
                  backgroundColor: Colors.white12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.redAccent : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 74,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: color.withOpacity(0.9), fontWeight: FontWeight.w800, fontSize: 11.5)),
          ],
        ),
      ),
    );
  }
}