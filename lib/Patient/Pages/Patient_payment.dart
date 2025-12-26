import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../Pages/NotificationsPage.dart';
import 'Patient_paymentDetails.dart';

class PatientPayment extends StatefulWidget {
  final Map<String, dynamic> hospitalData;
  const PatientPayment({super.key, required this.hospitalData});

  @override
  State<PatientPayment> createState() => _PatientPaymentState();
}

class _PatientPaymentState extends State<PatientPayment> {
  late List<Map<String, dynamic>> payments;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadPayments();
  }

  // ---------- Load & Sort Payments ----------
  void loadPayments() {
    payments = List<Map<String, dynamic>>.from(
      widget.hospitalData["Payments"] ?? [],
    );

    payments.sort(
      (a, b) => parseDate(b["createdAt"]).compareTo(parseDate(a["createdAt"])),
    );
  }

  // ---------- Refresh ----------
  Future<void> refreshPage() async {
    setState(() => isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    loadPayments();
    setState(() => isLoading = false);
  }

  // ---------- DATE PARSER ----------
  DateTime parseDate(String date) {
    try {
      return DateFormat("yyyy-MM-dd hh:mm a").parse(date);
    } catch (e) {
      return DateTime.now();
    }
  }

  // ---------- TIME AGO ----------
  String timeAgo(String dateString) {
    DateTime date = parseDate(dateString);
    Duration diff = DateTime.now().difference(date);

    if (diff.inDays == 0) return "Today";
    if (diff.inDays == 1) return "Yesterday";
    return "${diff.inDays} days ago";
  }

  // ---------- FEE TYPE COLOR ----------
  Color feeColor(String type) {
    switch (type) {
      case "REGISTRATIONFEE":
        return Colors.teal;
      case "TESTINGFEESANDSCANNINGFEE":
        return Colors.deepOrange;
      case "MEDICINETONICINJECTIONFEES":
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // ---------- FEE TYPE ICON ----------
  IconData feeIcon(String type) {
    switch (type) {
      case "REGISTRATIONFEE":
        return Icons.receipt_long;
      case "TESTINGFEESANDSCANNINGFEE":
        return Icons.science_outlined;
      case "MEDICINETONICINJECTIONFEES":
        return Icons.medication_liquid;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: Color(0xFFBF955E),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  const Text(
                    "Payment History",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: refreshPage,
        child: payments.isEmpty
            ? const Center(child: Text("No payment history found"))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  return _paymentCard(payments[index]);
                },
              ),
      ),
    );
  }

  // ---------- PAYMENT CARD ----------
  Widget _paymentCard(Map<String, dynamic> p) {
    Color feeC = feeColor(p["type"]);
    Color statusColor = p["status"] == "PAID" ? Colors.green : Colors.redAccent;

    return GestureDetector(
      onTapDown: (_) => setState(() => isLoading = true),
      onTapUp: (_) => setState(() => isLoading = false),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentDetailsPage(
              payment: p,
              hospitalData: widget.hospitalData,
            ),
          ),
        );
      },
      child: AnimatedScale(
        scale: isLoading ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.75),
                Colors.white.withOpacity(0.55),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Icon Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [feeC.withOpacity(0.85), feeC.withOpacity(0.55)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: feeC.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(feeIcon(p["type"]), size: 30, color: Colors.white),
              ),
              const SizedBox(width: 16),
              // Right Side Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      p["reason"] ?? "",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Amount & Status
                    Row(
                      children: [
                        Text(
                          "₹${p["amount"]}",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: feeC,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withOpacity(0.30),
                                blurRadius: 2,
                                spreadRadius: 0.6,
                              ),
                            ],
                          ),
                          child: Text(
                            p["status"],
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Time Ago
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeAgo(p["createdAt"]),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
