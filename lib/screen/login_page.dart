import 'package:flutter/material.dart';
import '../service/api_service.dart';
import 'home_page.dart';
import 'otp_verify_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    final loggedIn = await ApiService.isLoggedIn();
    if (loggedIn && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      setState(() => loading = false);
    }
  }

  Future<void> sendOtp() async {
    final ok = await ApiService.sendOtp(emailCtrl.text.trim());
    if (ok && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OTPVerifyPage(email: emailCtrl.text.trim()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: sendOtp,
              child: const Text("Send OTP"),
            )
          ],
        ),
      ),
    );
  }
}