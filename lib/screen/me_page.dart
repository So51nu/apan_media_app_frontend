import 'package:flutter/material.dart';
import '../service/api_service.dart';
import 'login_page.dart';

class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  bool loading = true;
  Map<String, dynamic>? me;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final data = await ApiService.me();
    if (!mounted) return;
    setState(() {
      me = data;
      loading = false;
    });
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: const Text("Me"),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : me == null
          ? Center(
        child: TextButton(
          onPressed: _load,
          child: const Text("Retry", style: TextStyle(color: Colors.white)),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (me!["email"] ?? me!["username"] ?? "User").toString(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text("User ID: ${me!["id"]}", style: const TextStyle(color: Colors.white60)),
            ],
          ),
        ),
      ),
    );
  }
}