import 'package:flutter/material.dart';
import '../service/api_service.dart';
import 'video_player_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int bottomIndex = 0;

  // top tabs like screenshot
  final tabs = const [
    ("POPULAR", "popular"),
    ("MUST WATCH", "must_watch"),
    ("NEW & HOT", "new_hot"),
    ("RATING", "rating"),
  ];

  int tabIndex = 0;
  List<dynamic> videos = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final list = await ApiService.fetchVideos(category: tabs[tabIndex].$2);
    if (!mounted) return;
    setState(() {
      videos = list;
      loading = false;
    });
  }

  String get currentCategory => tabs[tabIndex].$2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          children: [
            // Top search + dev mode + banner
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(width: 12),
                          Icon(Icons.search, color: Colors.white60),
                          SizedBox(width: 10),
                          Text(
                            "Search...",
                            style: TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text("DEV MODE",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),

            // Top tabs
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, i) {
                  final selected = i == tabIndex;
                  return InkWell(
                    onTap: () async {
                      setState(() => tabIndex = i);
                      await _load();
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tabs[i].$1,
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.white60,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: selected ? 28 : 0,
                          height: 3,
                          decoration: BoxDecoration(
                            color: selected ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        )
                      ],
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 24),
                itemCount: tabs.length,
              ),
            ),

            const SizedBox(height: 10),

            // Video grid
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
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
                    final trending = (v["is_trending"] == true);

                    return InkWell(
                      onTap: (videoUrl == null || videoUrl.isEmpty)
                          ? null
                          : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VideoPlayerPage(
                              title: title,
                              videoUrl: videoUrl,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // poster
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  Container(
                                    color: Colors.white.withOpacity(0.08),
                                    child: thumb == null
                                        ? const Center(
                                      child: Icon(Icons.movie, color: Colors.white38),
                                    )
                                        : Image.network(
                                      thumb,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (_, __, ___) =>
                                      const Center(child: Icon(Icons.broken_image)),
                                    ),
                                  ),
                                  if (trending)
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom nav like screenshot
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: bottomIndex,
        backgroundColor: const Color(0xFF0F0F0F),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        onTap: (i) {
          setState(() => bottomIndex = i);

          // For now: only Home changes UI. Later you can map:
          // 0 Home -> popular tabs screen
          // 1 Trending -> category=trending
          // 2 VIP -> category=vip
          // 3 Continue -> category=continue
          // 4 Me -> profile page
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.local_fire_department), label: "Trending"),
          BottomNavigationBarItem(icon: Icon(Icons.workspace_premium), label: "VIP"),
          BottomNavigationBarItem(icon: Icon(Icons.play_circle_fill), label: "Continue"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Me"),
        ],
      ),
    );
  }
}