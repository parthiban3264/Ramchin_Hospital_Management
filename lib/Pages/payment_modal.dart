import 'dart:async';

import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

const Color hospitalAccentColor = Color(0xFFBF955E);

class PaymentModal extends StatefulWidget {
  final double registrationFee;
  const PaymentModal({super.key, required this.registrationFee});

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (mounted) {
      Navigator.pop(context, {
        'paymentStatus': true,
        'paymentMode': 'OnlinePay',
        'amount': widget.registrationFee,
      });
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      Navigator.pop(context, {
        'paymentStatus': false,
        'paymentMode': 'OnlinePay',
        'amount': widget.registrationFee,
      });
    }
  }

  // void _openRazorpay() {
  //   var options = {
  //     'key': 'rzp_test_EH1UEwLILEPXCj',
  //     'amount': (widget.registrationFee * 100).toInt(),
  //     'name': 'Hospital Management',
  //     'description': 'Consultation Payment',
  //     'prefill': {'contact': '9999999999', 'email': 'test@example.com'},
  //     'theme.color': '#BF955E',
  //   };
  //
  //   try {
  //     _razorpay.open(options);
  //   } catch (e) {
  //     Navigator.pop(context, {
  //       'paymentStatus': false,
  //       'paymentMode': 'OnlinePay',
  //       'amount': widget.registrationFee,
  //     });
  //   }
  // }
  //
  // void _manualPayDialog() async {
  //   final result = await showDialog<Map<String, dynamic>>(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (_) => ManualPayDialog(
  //       primaryColor: hospitalAccentColor,
  //       registrationFee: widget.registrationFee,
  //     ),
  //   );
  //   if (result != null && mounted) Navigator.pop(context, result);
  // }
  //
  // void _finalPayDialog() async {
  //   final result = await showDialog<Map<String, dynamic>>(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (_) => FinalPayDialog(
  //       primaryColor: hospitalAccentColor,
  //       finalFee: widget.registrationFee,
  //     ),
  //   );
  //   if (result != null && mounted) Navigator.pop(context, result);
  // }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 100),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: bottomInset + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Choose Payment Method",
              style: TextStyle(
                color: hospitalAccentColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Booking Fees: ₹ ${widget.registrationFee.toStringAsFixed(0)}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 28),
            _buildCardOption(
              title: "Online",
              icon: Icons.payment,
              onTap: () {
                Navigator.pop(context, {
                  'paymentStatus': true,
                  'paymentMode': 'OnlinePay',
                  'amount': widget.registrationFee,
                });
              },
            ),
            const SizedBox(height: 16),
            _buildCardOption(
              title: "Cash",
              icon: Icons.handshake,
              onTap: () {
                Navigator.pop(context, {
                  'paymentStatus': true,
                  'paymentMode': 'ManualPay',
                  'amount': widget.registrationFee,
                });
              },
              cardColor: Colors.green.shade50,
              iconColor: Colors.green.shade700,
            ),

            // const SizedBox(height: 16),
            // _buildCardOption(
            //   title: "Final Pay (Later)",
            //   icon: Icons.schedule,
            //   onTap: _finalPayDialog,
            //   cardColor: Colors.grey.shade100,
            //   iconColor: Colors.grey.shade700,
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardOption({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color cardColor = Colors.white,
    Color iconColor = hospitalAccentColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      splashColor: hospitalAccentColor.withValues(alpha: 0.25),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: hospitalAccentColor.withValues(alpha: 0.3)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: iconColor,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.black38,
            ),
          ],
        ),
      ),
    );
  }
}

// --- Manual Pay Dialog ---

class ManualPayDialog extends StatefulWidget {
  final Color primaryColor;
  final double registrationFee;

  const ManualPayDialog({
    super.key,
    required this.primaryColor,
    required this.registrationFee,
  });

  @override
  State<ManualPayDialog> createState() => _ManualPayDialogState();
}

class _ManualPayDialogState extends State<ManualPayDialog> {
  late int _secondsLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsLeft = 240;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 120),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: bottomInset + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.handshake, size: 52, color: widget.primaryColor),
            const SizedBox(height: 14),
            Text(
              "Manual Payment",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: widget.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Confirm patient has paid manually.\nTimer: $minutes:$seconds",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, null),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.shade700),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        'paymentStatus': true,
                        'paymentMode': 'ManualPay',
                        'amount': widget.registrationFee,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      "Mark as Paid",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- Final Pay Dialog ---

class FinalPayDialog extends StatelessWidget {
  final Color primaryColor;
  final double finalFee;

  const FinalPayDialog({
    super.key,
    required this.primaryColor,
    required this.finalFee,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 8,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 100),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: bottomInset + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, size: 52, color: primaryColor),
            const SizedBox(height: 14),
            Text(
              "Final Payment",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Remaining payment of ₹${finalFee.toStringAsFixed(2)} will be added for final settlement.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'paymentStatus': false,
                  'paymentMode': 'Final Pay',
                  'amount': finalFee,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                "Confirm",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, null),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
