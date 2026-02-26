import 'package:flutter/material.dart';
import 'common_grid_page.dart';

class TrendingPage extends StatelessWidget {
  const TrendingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: CommonGridPage(category: "trending"),
    );
  }
}