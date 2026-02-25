import 'package:flutter/material.dart';
import '../service/api_service.dart';
import 'reels_page.dart';

class ContinuePage extends StatefulWidget {
  const ContinuePage({super.key});

  @override
  State<ContinuePage> createState() => _ContinuePageState();
}

class _ContinuePageState extends State<ContinuePage> {
  bool loading = true;
  List<dynamic> videos = [];

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
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : videos.isEmpty
            ? Center(
          child: TextButton(
            onPressed: _load,
            child: const Text("Nothing to continue", style: TextStyle(color: Colors.white)),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: videos.length,
          itemBuilder: (_, index) {
            final v = videos[index];
            final title = (v["title"] ?? "").toString();
            final thumb = v["thumbnail_url"]?.toString();

            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 56,
                  height: 56,
                  color: Colors.white12,
                  child: thumb == null
                      ? const Icon(Icons.movie, color: Colors.white38)
                      : Image.network(thumb, fit: BoxFit.cover),
                ),
              ),
              title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              subtitle: const Text("Continue watching", style: TextStyle(color: Colors.white60)),
              onTap: () {
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
              },
            );
          },
        ),
      ),
    );
  }
}