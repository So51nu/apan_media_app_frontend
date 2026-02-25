import 'package:flutter/material.dart';
import 'common_grid_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int bottomIndex = 0;

  // Header tabs
  final tabs = const [
    ("POPULAR", "popular"),
    ("MUST WATCH", "must_watch"),
    ("NEW & HOT", "new_hot"),
    ("RATING", "rating"),
  ];

  int tabIndex = 0;

  String _pageCategory() {
    // bottom nav category mapping
    if (bottomIndex == 0) return tabs[tabIndex].$2; // Home uses top tab category
    if (bottomIndex == 1) return "trending";
    if (bottomIndex == 2) return "vip";
    if (bottomIndex == 3) return "continue"; // if you want separate endpoint later, you can change
    return "me"; // profile later
  }

  @override
  Widget build(BuildContext context) {
    final currentCategory = _pageCategory();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          children: [
            // ✅ Header (fixed)
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
                          Text("Search...", style: TextStyle(color: Colors.white54, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(18)),
                    child: const Text("DEV MODE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),

            // ✅ Top tabs (fixed on all pages)
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, i) {
                  final selected = i == tabIndex;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        tabIndex = i;
                        bottomIndex = 0; // when top tab clicked, go to Home
                      });
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
                        ),
                      ],
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 24),
                itemCount: tabs.length,
              ),
            ),

            const SizedBox(height: 10),

            // ✅ Body (switches by bottom nav)
            Expanded(
              child: IndexedStack(
                index: bottomIndex,
                children: [
                  CommonGridPage(category: tabs[tabIndex].$2), // Home category via top tabs
                  const CommonGridPage(category: "trending"),
                  const CommonGridPage(category: "vip"),
                  const CommonGridPage(category: "continue"), // optional: later use /continue endpoint
                  const CommonGridPage(category: "me"),       // later profile page
                ],
              ),
            ),
          ],
        ),
      ),

      // ✅ Footer fixed
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: bottomIndex,
        backgroundColor: const Color(0xFF0F0F0F),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => bottomIndex = i),
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