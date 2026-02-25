import 'package:flutter/material.dart';
import '../service/api_service.dart';
import 'reels_page.dart';

class CommonGridPage extends StatefulWidget {
  final String category; // popular / must_watch / trending / vip / rating / etc.

  const CommonGridPage({super.key, required this.category});

  @override
  State<CommonGridPage> createState() => _CommonGridPageState();
}

class _CommonGridPageState extends State<CommonGridPage> {
  List<dynamic> videos = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CommonGridPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final list = await ApiService.fetchVideos(category: widget.category);
    if (!mounted) return;
    setState(() {
      videos = list;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    if (videos.isEmpty) {
      return const Center(
        child: Text("No videos", style: TextStyle(color: Colors.white70)),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.62,
        ),
        itemCount: videos.length,
        itemBuilder: (_, index) {
          final v = videos[index];
          final title = (v["title"] ?? "").toString();
          final subtitle = (v["subtitle"] ?? "").toString();
          final thumb = v["thumbnail_url"]?.toString();
          final videoUrl = v["video_url"]?.toString();

          final isTrendingFlag = (v["is_trending"] == true);
          final isTrendingCategory = (v["category"]?.toString() == "trending");
          final showTrendingBadge = isTrendingFlag || isTrendingCategory || widget.category == "trending";

          return InkWell(
            onTap: (videoUrl == null || videoUrl.isEmpty)
                ? null
                : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReelsPage(
                    category: widget.category,
                    startIndex: index,
                    initialList: videos,
                  ),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Container(
                          color: Colors.white.withOpacity(0.08),
                          child: thumb == null
                              ? const Center(child: Icon(Icons.movie, color: Colors.white38))
                              : Image.network(
                            thumb,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) =>
                            const Center(child: Icon(Icons.broken_image, color: Colors.white38)),
                          ),
                        ),

                        // ✅ FIXED: Trending badge
                        if (showTrendingBadge)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("🔥", style: TextStyle(fontSize: 12)),
                                  SizedBox(width: 4),
                                  Text(
                                    "Trending",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}