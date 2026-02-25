// lib/screen/video_player_page.dart
//
// ✅ Reel / Fullscreen player (like Reels)
// - Video fills the screen (cover), centered
// - Proper working icons:
//   Like/Unlike: toggles state (UI)
//   Share: opens OS share sheet (needs share_plus)
//   Save: downloads file to app documents (needs path_provider) [basic demo]
//   More: bottom sheet
// - Tap to show/hide controls
// - Play/Pause + progress bar + time
//
// 🔧 Add dependencies in pubspec.yaml:
//   share_plus: ^10.0.2
//   path_provider: ^2.1.4
//   http: ^1.2.2
//
// Then: flutter pub get

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class VideoPlayerPage extends StatefulWidget {
  final String title;
  final String videoUrl;

  const VideoPlayerPage({
    super.key,
    required this.title,
    required this.videoUrl,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late final VideoPlayerController _controller;

  bool _showUi = true;
  bool _liked = false;
  bool _disliked = false;

  bool _saving = false;

  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _controller.setLooping(true);
        _controller.play();
        _autoHide();
      }).catchError((e) {
        debugPrint("Video init error: $e");
      });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _autoHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _showUi = false);
    });
  }

  void _toggleUi() {
    setState(() => _showUi = !_showUi);
    if (_showUi) _autoHide();
  }

  void _playPause() {
    if (!_controller.value.isInitialized) return;
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
      _showUi = true;
    });
    _autoHide();
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, "0");
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return h > 0 ? "${two(h)}:${two(m)}:${two(s)}" : "${two(m)}:${two(s)}";
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _share() async {
    // ✅ Proper OS share sheet
    await Share.share(widget.videoUrl, subject: widget.title);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final uri = Uri.parse(widget.videoUrl);
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        _snack("Download failed (${res.statusCode})");
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final fileName = "video_${DateTime.now().millisecondsSinceEpoch}.mp4";
      final file = File("${dir.path}/$fileName");

      await file.writeAsBytes(res.bodyBytes);
      _snack("Saved to app storage ✅");
    } catch (e) {
      _snack("Save error: $e");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _more() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: const Icon(Icons.link, color: Colors.white),
                  title: const Text("Copy link", style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _snack("Copy link (connect clipboard later)");
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.report, color: Colors.white),
                  title: const Text("Report", style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _snack("Report (connect API later)");
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialized = _controller.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleUi,
        child: Stack(
          children: [
            // ✅ FULLSCREEN video (Reels style)
            Positioned.fill(
              child: initialized
                  ? FittedBox(
                fit: BoxFit.cover, // cover full screen
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              )
                  : const Center(child: CircularProgressIndicator()),
            ),

            // ✅ Top bar (back + title)
            if (_showUi)
              Positioned(
                top: MediaQuery.of(context).padding.top + 6,
                left: 8,
                right: 8,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ✅ Center play/pause button
            if (_showUi && initialized)
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
                        _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                ),
              ),

            // ✅ Right-side action buttons (Reels style)
            Positioned(
              right: 10,
              bottom: 110,
              child: Column(
                children: [
                  _ReelAction(
                    icon: _liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    label: "Like",
                    active: _liked,
                    onTap: () {
                      setState(() {
                        _liked = !_liked;
                        if (_liked) _disliked = false;
                      });
                      _autoHide();
                    },
                  ),
                  const SizedBox(height: 14),
                  _ReelAction(
                    icon: _disliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                    label: "Unlike",
                    active: _disliked,
                    onTap: () {
                      setState(() {
                        _disliked = !_disliked;
                        if (_disliked) _liked = false;
                      });
                      _autoHide();
                    },
                  ),
                  const SizedBox(height: 14),
                  _ReelAction(
                    icon: Icons.share_outlined,
                    label: "Share",
                    onTap: () async {
                      await _share();
                      _autoHide();
                    },
                  ),
                  const SizedBox(height: 14),
                  _ReelAction(
                    icon: _saving ? Icons.downloading : Icons.download_outlined,
                    label: "Save",
                    onTap: () async {
                      await _save();
                      _autoHide();
                    },
                  ),
                  const SizedBox(height: 14),
                  _ReelAction(
                    icon: Icons.more_vert,
                    label: "More",
                    onTap: () {
                      _more();
                      _autoHide();
                    },
                  ),
                ],
              ),
            ),

            // ✅ Bottom progress + time
            if (_showUi && initialized)
              Positioned(
                left: 12,
                right: 12,
                bottom: 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VideoProgressIndicator(
                      _controller,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      colors: VideoProgressColors(
                        playedColor: Colors.redAccent,
                        bufferedColor: Colors.white30,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _fmt(_controller.value.position),
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          _fmt(_controller.value.duration),
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReelAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ReelAction({
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
        width: 66,
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
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.9),
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

