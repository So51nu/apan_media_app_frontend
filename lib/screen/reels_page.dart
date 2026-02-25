import 'package:flutter/material.dart';
import '../service/api_service.dart';
import 'reels_player_item.dart';

class ReelsPage extends StatefulWidget {
  final String category;
  final int startIndex;
  final List<dynamic>? initialList; // optional (home se pass karoge)

  const ReelsPage({
    super.key,
    required this.category,
    this.startIndex = 0,
    this.initialList,
  });

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  late final PageController _pc;

  final List<Map<String, dynamic>> _videos = [];
  int _page = 1;
  bool _loading = true;
  bool _hasMore = true;
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    _pc = PageController(initialPage: widget.startIndex);
    _initLoad();
  }

  Future<void> _initLoad() async {
    setState(() => _loading = true);

    // ✅ If Home passed initial list, use it first (fast)
    if (widget.initialList != null && widget.initialList!.isNotEmpty) {
      _videos
        ..clear()
        ..addAll(widget.initialList!.cast<Map<String, dynamic>>());
      setState(() => _loading = false);
      // Also start prefetch in background (optional)
      _prefetchIfShort();
      return;
    }

    // Otherwise fetch from feed
    final data = await ApiService.fetchFeed(page: 1, pageSize: 10, category: widget.category);
    final results = (data["results"] as List).cast<Map<String, dynamic>>();

    if (!mounted) return;
    setState(() {
      _videos
        ..clear()
        ..addAll(results);
      _hasMore = data["has_more"] == true;
      _page = 1;
      _loading = false;
    });
  }

  Future<void> _prefetchIfShort() async {
    if (_videos.length >= 8) return;
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _fetching) return;
    _fetching = true;

    final next = _page + 1;
    final data = await ApiService.fetchFeed(page: next, pageSize: 10, category: widget.category);
    final results = (data["results"] as List).cast<Map<String, dynamic>>();

    if (!mounted) return;
    setState(() {
      _videos.addAll(results);
      _hasMore = data["has_more"] == true;
      _page = next;
    });

    _fetching = false;
  }

  void _onPageChanged(int i) {
    // near end -> load more
    if (i >= _videos.length - 3) {
      _loadMore();
    }
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_videos.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: TextButton(
            onPressed: _initLoad,
            child: const Text("No videos. Tap to refresh", style: TextStyle(color: Colors.white)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pc,
        scrollDirection: Axis.vertical,
        onPageChanged: _onPageChanged,
        itemCount: _videos.length,
        itemBuilder: (_, index) {
          return ReelsPlayerItem(
            video: _videos[index],
            onUpdateFromServer: (updatedVideo) {
              setState(() => _videos[index] = updatedVideo);
            },
          );
        },
      ),
    );
  }
}