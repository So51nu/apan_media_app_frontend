import 'package:flutter/material.dart';
import '../service/api_service.dart';
import 'reels_player_item.dart';
import 'paywall_page.dart';

class ReelsPage extends StatefulWidget {
  final String category;
  final int startIndex;
  final List<dynamic>? initialList;

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

  int _currentIndex = 0;
  bool _checkingGate = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex;
    _pc = PageController(initialPage: widget.startIndex);
    _initLoad();
  }

  Future<void> _initLoad() async {
    setState(() => _loading = true);

    if (widget.initialList != null && widget.initialList!.isNotEmpty) {
      _videos
        ..clear()
        ..addAll(widget.initialList!.cast<Map<String, dynamic>>());
      setState(() => _loading = false);

      // ✅ Gate check for first video
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _gateCheckAt(_currentIndex);
      });

      _prefetchIfShort();
      return;
    }

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gateCheckAt(_currentIndex);
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

  // ✅ MAIN FIX: every time user changes video, gate-check that video
  Future<void> _gateCheckAt(int index) async {
    if (_checkingGate) return;
    if (index < 0 || index >= _videos.length) return;

    final v = _videos[index];
    final videoId = (v["id"] as int?);

    if (videoId == null) return;

    _checkingGate = true;

    final r = await ApiService.watchStart(videoId);

    if (!mounted) return;

    if (r["allowed"] == true) {
      _checkingGate = false;
      return;
    }

    // ❌ Not allowed => open Paywall
    final unlocked = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PaywallPage(
          reason: r["reason"]?.toString() ?? "PAYWALL",
        ),
      ),
    );

    // If not unlocked => force back to previous allowed video
    if (unlocked != true) {
      final backTo = _currentIndex;
      _pc.animateToPage(
        backTo,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      // ✅ unlocked => allow this video now
      // run gate-check again just in case (will return allowed)
      await Future.delayed(const Duration(milliseconds: 150));
      await _gateCheckAt(index);
    }

    _checkingGate = false;
  }

  void _onPageChanged(int i) {
    // load more near end
    if (i >= _videos.length - 3) {
      _loadMore();
    }

    // ✅ gate check
    final prev = _currentIndex;
    _currentIndex = i;
    _gateCheckAt(i).then((_) {
      // if paywall bounced, index may revert
      if (!mounted) return;
      if (_pc.hasClients) {
        // keep safe
      }
    });
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