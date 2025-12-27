import 'package:flutter/material.dart';

import '../Pages/Accounts/FinancePage.dart';

String getDisplayType(Map<String, dynamic> p) {
  if (p['type'] != null) {
    String type = p['type'].toString().toUpperCase();

    // Handle TEST + SCAN combined case
    if (type == "TESTINGFEESANDSCANNINGFEE") {
      if (p['TestingAndScanningPatients'] != null &&
          (p['TestingAndScanningPatients'] as List).isNotEmpty) {
        final set = (p['TestingAndScanningPatients'] as List)
            .map((e) => e['type'].toString().toUpperCase())
            .toSet();

        if (set.length == 1) return set.first; // Test OR Scan
        return "TEST + SCAN"; // Both types
      }
    }

    return type;
  }
  return "UNKNOWN";
}

// ------------------------------
Widget _buildSummaryCard({
  FinanceFilter? filter,
  required List<Map<String, dynamic>> visiblePayments,
}) {
  // Filter payments by type
  List<Map<String, dynamic>> filterPayments(FinanceFilter? f) {
    if (f == null || f == FinanceFilter.all) return visiblePayments;

    switch (f) {
      case FinanceFilter.register:
        return visiblePayments
            .where((p) => getDisplayType(p) == "REGISTRATIONFEE")
            .toList();
      case FinanceFilter.medical:
        return visiblePayments
            .where((p) => getDisplayType(p) == "MEDICINETONICINJECTIONFEES")
            .toList();
      case FinanceFilter.test:
        return visiblePayments
            .where((p) => getDisplayType(p) == "TEST")
            .toList();
      case FinanceFilter.scan:
        return visiblePayments
            .where((p) => getDisplayType(p) == "SCAN")
            .toList();
      default:
        return visiblePayments;
    }
  }

  final filteredPayments = filterPayments(filter);

  // Calculate total of filtered payments
  double total = filteredPayments.fold(0.0, (sum, p) {
    final a = p['amount'];
    if (a is num) return sum + a.toDouble();
    if (a is String) return sum + (double.tryParse(a) ?? 0.0);
    return sum;
  });

  // Prepare list of breakdown cards
  Map<String, Map<String, dynamic>> breakdownMap = {
    "Register": {
      "total": filterPayments(FinanceFilter.register).fold(
        0.0,
        (p, e) =>
            p +
            ((e['amount'] is num)
                ? e['amount']
                : double.tryParse("${e['amount']}") ?? 0.0),
      ),
      "color": const Color(0xFFD6F5D6),
      "icon": Icons.how_to_reg,
    },
    "Medical": {
      "total": filterPayments(FinanceFilter.medical).fold(
        0.0,
        (p, e) =>
            p +
            ((e['amount'] is num)
                ? e['amount']
                : double.tryParse("${e['amount']}") ?? 0.0),
      ),
      "color": const Color(0xFFFFD6E7),
      "icon": Icons.medical_services,
    },
    "Test": {
      "total": filterPayments(FinanceFilter.test).fold(
        0.0,
        (p, e) =>
            p +
            ((e['amount'] is num)
                ? e['amount']
                : double.tryParse("${e['amount']}") ?? 0.0),
      ),
      "color": const Color(0xFFD6E8FF),
      "icon": Icons.science,
    },
    "Scan": {
      "total": filterPayments(FinanceFilter.scan).fold(
        0.0,
        (p, e) =>
            p +
            ((e['amount'] is num)
                ? e['amount']
                : double.tryParse("${e['amount']}") ?? 0.0),
      ),
      "color": const Color(0xFFD6FFFF),
      "icon": Icons.scanner,
    },
  };

  // Determine which breakdown cards to show
  List<Widget> breakdownCards = [];
  if (filter == null || filter == FinanceFilter.all) {
    // Show all cards
    breakdownMap.forEach((key, value) {
      breakdownCards.add(
        _buildCollectionCard(
          key,
          value['total'],
          value['color'],
          value['icon'],
        ),
      );
    });
  } else {
    // Show only the filtered card
    String key = filter.name;
    if (breakdownMap.containsKey(key)) {
      final value = breakdownMap[key]!;
      breakdownCards.add(
        _buildCollectionCard(
          key,
          value['total'],
          value['color'],
          value['icon'],
        ),
      );
    }
  }

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
      border: Border.all(
        color: const Color(0xFFC59A62).withOpacity(0.25),
        width: 1.2,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEDBA77), Color(0xFFC59A62)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.assessment, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Text(
                filter == null || filter == FinanceFilter.all
                    ? "Today's Summary"
                    : "${filter.name} Collection",
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  "${filteredPayments.length}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Total Collection - full width
        _buildCollectionCard(
          "Total Collection",
          total,
          Colors.green,
          Icons.currency_rupee,
          fullWidth: true,
        ),

        const SizedBox(height: 16),

        // Display relevant breakdown cards
        if (breakdownCards.isNotEmpty)
          Wrap(spacing: 12, runSpacing: 12, children: breakdownCards),
      ],
    ),
  );
}

// Collection card widget
Widget _buildCollectionCard(
  String title,
  double amount,
  Color color,
  IconData icon, {
  bool fullWidth = false,
}) {
  return Container(
    width: fullWidth ? double.infinity : 160,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    decoration: BoxDecoration(
      color: color.withOpacity(0.3),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "₹ ${amount.toStringAsFixed(1)}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
