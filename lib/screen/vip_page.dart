import 'package:flutter/material.dart';
import 'common_grid_page.dart';

class VipPage extends StatelessWidget {
  const VipPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: CommonGridPage(category: "vip"),
    );
  }
}