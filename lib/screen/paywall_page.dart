import 'dart:async';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../service/api_service.dart';

class PaywallPage extends StatefulWidget {
  final String reason;
  const PaywallPage({super.key, required this.reason});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  late Razorpay _razorpay;
  bool _busy = false;
  Completer<Map<String, dynamic>>? _paymentCompleter;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _onSuccess(PaymentSuccessResponse r) async {
    // for ORDER flow, verify on server
    final c = _paymentCompleter;
    if (c == null || c.isCompleted) return;
    c.complete({
      "razorpay_payment_id": r.paymentId,
      "razorpay_order_id": r.orderId,
      "razorpay_signature": r.signature,
    });
  }

  void _onError(PaymentFailureResponse r) {
    final c = _paymentCompleter;
    if (c == null || c.isCompleted) return;
    c.completeError("Payment failed: ${r.code} ${r.message}");
  }

  void _onExternalWallet(ExternalWalletResponse r) {}

  Future<void> _buyPass(int amountPaisa) async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final order = await ApiService.createOrder(amountPaisa);
      final key = order["key_id"]?.toString() ?? "";
      final orderId = order["order_id"]?.toString() ?? "";
      final amount = order["amount"] as int;

      if (key.isEmpty || orderId.isEmpty) throw "Invalid order response";

      _paymentCompleter = Completer<Map<String, dynamic>>();

      _razorpay.open({
        "key": key,
        "amount": amount,
        "currency": "INR",
        "name": "Apna Media",
        "description": "1-day pass",
        "order_id": orderId,
        "prefill": {"email": ""}, // optional
        "theme": {"color": "#ff3b30"},
      });

      final payload = await _paymentCompleter!.future.timeout(const Duration(minutes: 5));
      final verified = await ApiService.verifyPayment(payload);

      if (!mounted) return;
      if (verified["ok"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Unlocked for 1 days ✅")));
        Navigator.pop(context, true); // return success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Verify failed")));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
    } finally {
      _paymentCompleter = null;
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startSubscription() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final sub = await ApiService.createSubscription();
      final key = sub["key_id"]?.toString() ?? "";
      final subscriptionId = sub["subscription_id"]?.toString() ?? "";

      if (key.isEmpty || subscriptionId.isEmpty) throw "Invalid subscription response";

      // Subscription checkout (UPI AutoPay happens inside Razorpay UI based on user choice)
      _razorpay.open({
        "key": key,
        "subscription_id": subscriptionId,
        "name": "Apna Media",
        "description": "₹299/month AutoPay",
        "theme": {"color": "#ff3b30"},
      });

      // IMPORTANT:
      // Subscription activation comes via WEBHOOK (server updates entitlement).
      // So user should retry play after a few seconds or you can poll /me.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Subscription started. It will activate after authorization ✅")),
      );
      Navigator.pop(context, false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = _busy;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: const Text("Unlock"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),
            const Text("Limit reached", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text("Reason: ${widget.reason}", style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: const Text(
                "1 videos free done ✅\nTo watch more, buy 1-day .",
                style: TextStyle(color: Colors.white70, height: 1.3),
              ),
            ),

            const SizedBox(height: 16),

            _Btn(
              text: disabled ? "Please wait..." : "Buy 1-day pass ₹4",
              onTap: disabled ? null : () => _buyPass(400),
            ),
            const SizedBox(height: 10),
            // _Btn(
            //   text: disabled ? "Please wait..." : "Buy 2-day pass ₹5",
            //   onTap: disabled ? null : () => _buyPass(500),
            // ),
            // const SizedBox(height: 10),
            // _Btn(
            //   text: disabled ? "Please wait..." : "Buy 2-day pass ₹8",
            //   onTap: disabled ? null : () => _buyPass(800),
            // ),

            const SizedBox(height: 18),
            const Divider(color: Colors.white12),

            const SizedBox(height: 12),
            // _Btn(
            //   text: disabled ? "Please wait..." : "Enable AutoPay ₹299/month",
            //   onTap: disabled ? null : _startSubscription,
            // ),

            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Back", style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const _Btn({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF4D4D),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}