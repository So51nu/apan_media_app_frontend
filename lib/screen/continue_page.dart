import 'package:flutter/material.dart';
import '../service/api_service.dart';
import 'reels_page.dart';
import 'paywall_page.dart';

class ContinuePage extends StatefulWidget {
  const ContinuePage({super.key});

  @override
  State<ContinuePage> createState() => _ContinuePageState();
}

class _ContinuePageState extends State<ContinuePage> {
  List<dynamic> videos = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final list = await ApiService.fetchContinue();
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
      return const Center(child: Text("No continue videos", style: TextStyle(color: Colors.white70)));
    }

    // ✅ reuse same grid look quickly
    return SafeArea(
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
          final thumb = v["thumbnail_url"]?.toString();
          final title = (v["title"] ?? "").toString();
          final videoUrl = v["video_url"]?.toString();
          final videoId = (v["id"] as int);

          return InkWell(
            onTap: (videoUrl == null || videoUrl.isEmpty)
                ? null
                : () async {
              final r = await ApiService.watchStart(videoId);
              if (r["allowed"] == true) {
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReelsPage(
                      category: "continue",
                      startIndex: index,
                      initialList: videos,
                    ),
                  ),
                );
              } else {
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaywallPage(
                      reason: r["reason"]?.toString() ?? "PAYWALL",
                    ),
                  ),
                );
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: Colors.white.withOpacity(0.08),
                child: thumb == null
                    ? const Center(child: Icon(Icons.movie, color: Colors.white38))
                    : Image.network(thumb, fit: BoxFit.cover),
              ),
            ),
          );
        },
      ),
    );
  }
}