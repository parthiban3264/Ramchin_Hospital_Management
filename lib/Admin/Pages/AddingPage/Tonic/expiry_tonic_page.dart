import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../Services/Tonic_Service.dart';

class ExpiryTonicPage extends StatefulWidget {
  const ExpiryTonicPage({super.key});

  @override
  State<ExpiryTonicPage> createState() => _ExpiryTonicPageState();
}

class _ExpiryTonicPageState extends State<ExpiryTonicPage> {
  List<Map<String, dynamic>> expired = [];
  bool loading = true;

  static const Color danger = Colors.red;
  static const Color bg = Color(0xFFF6F7FB);

  @override
  void initState() {
    super.initState();
    loadExpired();
  }

  Future<void> loadExpired() async {
    final all = await TonicService().getAllTonics();
    final now = DateTime.now();

    expired = all.where((m) {
      final expiry = DateTime.tryParse(m['expiryDate'] ?? m['expiry'] ?? '');
      return expiry != null && expiry.isBefore(now);
    }).toList();

    setState(() => loading = false);
  }

  String formatDate(String? date) {
    if (date == null) return "-";
    final d = DateTime.tryParse(date);
    return d == null ? "-" : DateFormat("dd MMM yyyy").format(d);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    if (expired.isEmpty) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(
          child: Text(
            "No expired Tonics",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: expired.length,
        itemBuilder: (_, i) {
          final m = expired[i];
          final expiryDate = m['expiryDate'] ?? m['expiry'] ?? '-';

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: danger.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning, color: danger, size: 28),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m['medicianName'] ?? "-",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Code: ${m['medicianCode'] ?? "-"}",
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: danger.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "EXPIRED",
                  style: TextStyle(color: danger, fontWeight: FontWeight.bold),
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  "Expired on: ${formatDate(expiryDate)}",
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
