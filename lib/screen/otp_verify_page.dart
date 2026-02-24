import 'package:flutter/material.dart';
import '../service/api_service.dart';
import 'home_page.dart';

class OTPVerifyPage extends StatefulWidget {
  final String email;
  const OTPVerifyPage({super.key, required this.email});

  @override
  State<OTPVerifyPage> createState() => _OTPVerifyPageState();
}

class _OTPVerifyPageState extends State<OTPVerifyPage> {
  final otpCtrl = TextEditingController();

  Future<void> verify() async {
    final ok = await ApiService.verifyOtp(widget.email, otpCtrl.text.trim());
    if (ok && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
            (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify OTP")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("OTP sent to ${widget.email}"),
            TextField(
              controller: otpCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "OTP"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: verify,
              child: const Text("Verify"),
            )
          ],
        ),
      ),
    );
  }
}