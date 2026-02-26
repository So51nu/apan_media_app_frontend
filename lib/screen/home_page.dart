import 'package:flutter/material.dart';
import 'common_grid_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final tabs = const [
    ("POPULAR", "popular"),
    ("MUST WATCH", "must_watch"),
    ("NEW & HOT", "new_hot"),
    ("RATING", "rating"),
  ];

  int tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentCategory = tabs[tabIndex].$2;

    return SafeArea(
      child: Column(
        children: [
          // ✅ Top search + DEV MODE
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
                  child: const Text(
                    "DEV MODE",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),

          // ✅ Top tabs
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, i) {
                final selected = i == tabIndex;
                return InkWell(
                  onTap: () => setState(() => tabIndex = i),
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

          // ✅ Grid
          Expanded(
            child: CommonGridPage(category: currentCategory),
          ),
        ],
      ),
    );
  }
}