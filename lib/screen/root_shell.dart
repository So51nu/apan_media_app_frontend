import 'package:flutter/material.dart';
import 'home_page.dart';
import 'trending_page.dart';
import 'vip_page.dart';
import 'continue_page.dart';
import 'me_page.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int index = 0;

  final pages = const [
    HomePage(),
    TrendingPage(),
    VipPage(),
    ContinuePage(),
    MePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        backgroundColor: const Color(0xFF0F0F0F),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => index = i),
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