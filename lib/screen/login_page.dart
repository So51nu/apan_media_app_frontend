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
  bool rememberMe = true;

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    super.dispose();
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
    final email = emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email")),
      );
      return;
    }

    final ok = await ApiService.sendOtp(email);
    if (!mounted) return;

    if (ok) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OTPVerifyPage(email: email)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP send failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const pink = Color(0xFFFF7B87);
    const pinkDark = Color(0xFFFF5F72);

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Top pink header + pattern
            SizedBox(
              height: 320,
              width: double.infinity,
              child: CustomPaint(
                painter: TopPatternPainter(
                  baseColor: pink,
                  patternColor: Colors.white.withOpacity(0.22),
                ),
              ),
            ),

            // White wave
            Positioned(
              top: 210,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 140,
                child: CustomPaint(painter: WavePainter(color: Colors.white)),
              ),
            ),

            // Content
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 265),

                    const Text(
                      "Sign in",
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2D2D2D),
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 56,
                      height: 3,
                      decoration: BoxDecoration(
                        color: pinkDark,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 28),

                    const Text(
                      "Email",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF7A7A7A),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Email underline field
                    UnderlineField(
                      controller: emailCtrl,
                      hintText: "demo@email.com",
                      prefixIcon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      underlineColor: pinkDark.withOpacity(0.55),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        RememberMeTile(
                          value: rememberMe,
                          activeColor: pinkDark,
                          onChanged: (v) => setState(() => rememberMe = v),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            // Optional: forgot flow (later)
                          },
                          child: Text(
                            "",
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: pinkDark,
                            ),
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 22),

                    // Login button (Send OTP)
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pink,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // bottom text (same look)
                    Center(
                      child: Text.rich(
                        TextSpan(
                          style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
                          children: const [
                            TextSpan(text: ""),

                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 26),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- UI helpers ----------------

class UnderlineField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final Color underlineColor;

  const UnderlineField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    required this.underlineColor,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2D2D2D),
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: hintText,
        hintStyle: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFFBDBDBD),
        ),
        prefixIcon: Icon(prefixIcon, color: Color(0xFFBDBDBD), size: 20),
        border: UnderlineInputBorder(borderSide: BorderSide(color: underlineColor, width: 2)),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: underlineColor, width: 2)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: underlineColor, width: 2.2)),
      ),
    );
  }
}

class RememberMeTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const RememberMeTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: value ? activeColor : const Color(0xFFD8D8D8),
                width: 1.4,
              ),
              color: value ? activeColor : Colors.transparent,
            ),
            child: value ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
          ),
          const SizedBox(width: 8),
          const Text(
            "Remember Me",
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8A8A8A),
            ),
          ),
        ],
      ),
    );
  }
}

class TopPatternPainter extends CustomPainter {
  final Color baseColor;
  final Color patternColor;

  TopPatternPainter({required this.baseColor, required this.patternColor});

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = baseColor;
    canvas.drawRect(Offset.zero & size, base);

    final p = Paint()
      ..color = patternColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    for (int i = 0; i < 10; i++) {
      final y = 22.0 + i * 26.0;
      final path = Path()
        ..moveTo(-20, y)
        ..cubicTo(size.width * 0.25, y - 18, size.width * 0.55, y + 22, size.width * 0.85, y - 10)
        ..cubicTo(size.width * 1.05, y - 28, size.width * 1.15, y + 18, size.width + 40, y + 6);
      canvas.drawPath(path, p);
    }

    final ring = Paint()
      ..color = patternColor.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(Offset(size.width * 0.22, 95), 60, ring);
    canvas.drawCircle(Offset(size.width * 0.72, 140), 72, ring);
    canvas.drawCircle(Offset(size.width * 0.48, 55), 38, ring);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WavePainter extends CustomPainter {
  final Color color;
  WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    final path = Path()
      ..moveTo(0, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.05, size.width * 0.55, size.height * 0.35)
      ..quadraticBezierTo(size.width * 0.78, size.height * 0.58, size.width, size.height * 0.18)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


