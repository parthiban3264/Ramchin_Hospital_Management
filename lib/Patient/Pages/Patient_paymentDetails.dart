import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../Pages/NotificationsPage.dart';

class PaymentDetailsPage extends StatelessWidget {
  final Map<String, dynamic> payment;
  final Map<String, dynamic> hospitalData;

  const PaymentDetailsPage({
    super.key,
    required this.payment,
    required this.hospitalData,
  });

  // Safe date parser (falls back to now)
  DateTime parseDate(String? date) {
    if (date == null) return DateTime.now();
    try {
      return DateFormat("yyyy-MM-dd hh:mm a").parse(date);
    } catch (e) {
      // Try alternative common formats
      try {
        return DateFormat("yyyy-MM-dd HH:mm:ss").parse(date);
      } catch (_) {
        return DateTime.now();
      }
    }
  }

  String formatDate(String? date) {
    if (date == null) return "-";
    final d = parseDate(date);
    return DateFormat("dd MMM yyyy, hh:mm a").format(d);
  }

  Color getStatusColor(String? status) {
    switch ((status ?? "").toUpperCase()) {
      case "PAID":
        return Colors.green;
      case "PENDING":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Helper: safe access to lists in hospitalData
  List<Map<String, dynamic>> _asList(String key) {
    final raw = hospitalData[key];
    if (raw is List) {
      // ensure map type
      return raw.map<Map<String, dynamic>>((e) {
        if (e is Map<String, dynamic>) return e;
        if (e is Map) return Map<String, dynamic>.from(e);
        return <String, dynamic>{};
      }).toList();
    }
    return <Map<String, dynamic>>[];
  }

  // match payment.id to item["payment_Id"] - compare as strings (safe)
  bool _matchesPayment(dynamic itemPaymentId, dynamic paymentId) {
    if (itemPaymentId == null || paymentId == null) return false;
    return itemPaymentId.toString() == paymentId.toString();
  }

  List<Map<String, dynamic>> getMedicineItems() {
    final meds = _asList("MedicinePatients");
    return meds
        .where((m) => _matchesPayment(m["payment_Id"], payment["id"]))
        .toList();
  }

  List<Map<String, dynamic>> getInjectionItems() {
    final inj = _asList("InjectionPatients");
    return inj
        .where((i) => _matchesPayment(i["payment_Id"], payment["id"]))
        .toList();
  }

  List<Map<String, dynamic>> getTonicItems() {
    final t = _asList("TonicPatients");
    return t
        .where((x) => _matchesPayment(x["payment_Id"], payment["id"]))
        .toList();
  }

  List<Map<String, dynamic>> getTestItems() {
    final tests = _asList("TestingAndScannings");
    return tests
        .where((t) => _matchesPayment(t["payment_Id"], payment["id"]))
        .toList();
  }

  // compute sum of item totals (if available)
  num _sumTotals(List<Map<String, dynamic>> items, String field) {
    num sum = 0;
    for (var it in items) {
      final v = it[field];
      if (v is num) {
        sum += v;
      } else if (v is String) {
        final n = num.tryParse(v) ?? 0;
        sum += n;
      }
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = getStatusColor(payment["status"]?.toString());
    final medicineItems = getMedicineItems();
    final injectionItems = getInjectionItems();
    final tonicItems = getTonicItems();
    final testItems = getTestItems();

    final hasPrescription =
        medicineItems.isNotEmpty ||
        injectionItems.isNotEmpty ||
        tonicItems.isNotEmpty;
    final hasTests = testItems.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerCard(statusColor),
            const SizedBox(height: 24),

            _sectionTitle("Payment Information"),
            // _infoRow("Reason", payment["reason"] ?? "-"),
            // _infoRow("Amount", "₹${payment["amount"] ?? '-'}"),
            _infoRow("Payment Type", payment["paymentType"] ?? "-"),
            // _infoRow("Status", payment["status"] ?? "-"),
            _infoRow("Created", formatDate(payment["createdAt"])),

            // _infoRow("Updated", payment["updatedAt"] ?? "Not Updated"),
            const SizedBox(height: 20),

            if (hasPrescription) ...[
              _sectionTitle("Prescription Breakdown"),
              // header summary
              _summaryRow(
                "Prescription Total",
                "₹${_sumTotals(medicineItems, "total") + _sumTotals(injectionItems, "total") + _sumTotals(tonicItems, "total")}",
              ),
              const SizedBox(height: 8),

              if (medicineItems.isNotEmpty) _medicinesWidget(medicineItems),
              if (injectionItems.isNotEmpty) _injectionsWidget(injectionItems),
              if (tonicItems.isNotEmpty) _tonicsWidget(tonicItems),
              const SizedBox(height: 20),
            ],

            if (hasTests) ...[
              _sectionTitle("Testing & Scanning"),
              _testsWidget(testItems),
              const SizedBox(height: 20),
            ],

            if (!hasPrescription && !hasTests) ...[
              _sectionTitle("Notes"),
              Text(
                "No linked items found for this payment.",
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 20),
            ],

            _sectionTitle("Timeline History"),
            _timelineTile("Created At", payment["createdAt"]),
            _timelineTile("Last Updated", payment["updatedAt"]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ---------------- UI Building Blocks ----------------

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(95),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFBF955E),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                const Text(
                  "Payment Details",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
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
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.home, color: Colors.white),
                  onPressed: () {
                    int cnt = 0;
                    Navigator.popUntil(context, (route) => cnt++ >= 2);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerCard(Color statusColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.8),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            payment["reason"] ?? "Payment",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                "₹${payment["amount"] ?? '-'}",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade700,
                ),
              ),
              Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  payment["status"] ?? "PENDING",
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _summaryRow(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _medicinesWidget(List<Map<String, dynamic>> medicines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _subSectionTitle("Medicines"),
        ...medicines.map((m) {
          final med = m["Medician"] ?? {};
          final name = med["medicianName"] ?? med["medicianname"] ?? "Medicine";
          final qty = m["quantityNeeded"] ?? m["quantity"] ?? 1;
          final days = m["days"] ?? "-";
          final total = m["total"] ?? "-";
          return _itemTile(
            name.toString(),
            "Qty: $qty • Days: $days",
            "₹$total",
          );
        }),
      ],
    );
  }

  Widget _injectionsWidget(List<Map<String, dynamic>> injections) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _subSectionTitle("Injections"),
        ...injections.map((i) {
          final inj = i["Injection"] ?? {};
          final name =
              inj["injectionName"] ?? inj["injectionname"] ?? "Injection";
          final qty = i["quantity"] ?? 1;
          final total = i["total"] ?? "-";
          return _itemTile(name.toString(), "Qty: $qty", "₹$total");
        }),
      ],
    );
  }

  Widget _tonicsWidget(List<Map<String, dynamic>> tonics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _subSectionTitle("Tonics"),
        ...tonics.map((t) {
          final tonic = t["Tonic"] ?? {};
          final name = tonic["tonicName"] ?? tonic["tonicname"] ?? "Tonic";
          final qty = t["quantity"] ?? "-";
          final dose = t["Doase"] ?? t["Dose"] ?? "-";
          final total = t["total"] ?? "-";
          return _itemTile(
            name.toString(),
            "Qty: $qty • Dose: $dose",
            "₹$total",
          );
        }),
      ],
    );
  }

  Widget _testsWidget(List<Map<String, dynamic>> tests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tests.map((t) {
        final title = t["title"] ?? t["reason"] ?? "Test";
        final amount = t["amount"] ?? "-";
        final result = t["result"] ?? "-";
        final selectedOptions = t["selectedOptions"] is List
            ? List.from(t["selectedOptions"])
            : <dynamic>[];
        final selectedOptionResults =
            t["selectedOptionResults"] ?? <String, dynamic>{};
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "₹$amount",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (selectedOptions.isNotEmpty) ...[
                Text(
                  "Selected Options:",
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                ...selectedOptions.map<Widget>((opt) {
                  final res = selectedOptionResults[opt] ?? "-";
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(opt.toString()),
                        Text(
                          res.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
              Text(
                "Result: $result",
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _subSectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        t,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _itemTile(String title, String subtitle, String trailing) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ),
          Text(trailing, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _timelineTile(String label, dynamic value) {
    final display = value == null
        ? "Not available"
        : (value is String ? value : value.toString());
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.blue,
                child: const Icon(Icons.history, size: 14, color: Colors.white),
              ),
              Container(width: 3, height: 50, color: Colors.grey.shade300),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(display, style: const TextStyle(color: Colors.black87)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
