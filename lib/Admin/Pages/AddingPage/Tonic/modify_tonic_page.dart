import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../Services/Tonic_Service.dart';

class ModifyTonicPage extends StatefulWidget {
  const ModifyTonicPage({super.key});

  @override
  State<ModifyTonicPage> createState() => _ModifyTonicPageState();
}

class _ModifyTonicPageState extends State<ModifyTonicPage> {
  List<Map<String, dynamic>> tonics = [];
  List<Map<String, dynamic>> filtered = [];
  bool loading = true;

  final searchController = TextEditingController();

  static const Color primary = Color(0xFFBF955E);
  static const Color bg = Color(0xFFF6F7FB);

  @override
  void initState() {
    super.initState();
    fetchTonics();
  }

  Future<void> fetchTonics() async {
    tonics = await TonicService().getAllTonics();
    filtered = tonics.where((t) => daysLeft(t['expiryDate']) >= 0).toList();
    setState(() => loading = false);
  }

  void search(String value) {
    filtered = tonics.where((t) {
      final name = (t['tonicName'] ?? '').toString().toLowerCase();
      final code = (t['tonicCode'] ?? '').toString().toLowerCase();
      return name.contains(value.toLowerCase()) ||
          code.contains(value.toLowerCase());
    }).toList();
    setState(() {});
  }

  int daysLeft(String? date) {
    if (date == null) return 999;
    final d = DateTime.tryParse(date);
    if (d == null) return 999;
    return d.difference(DateTime.now()).inDays;
  }

  String formatDate(String? date) {
    if (date == null) return "-";
    final d = DateTime.tryParse(date);
    return d == null ? "-" : DateFormat("dd MMM yyyy").format(d);
  }

  Color statusColor(int days) => days <= 30 ? Colors.orange : Colors.green;

  Map<String, dynamic> toMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String) return jsonDecode(value);
    return {};
  }

  /// ---------------- UPDATE DIALOG ----------------
  void showUpdateDialog(Map t) {
    final stockMap = toMap(t['stock']);
    final amountMap = toMap(t['amount']);

    final Map<String, TextEditingController> stockCtrls = {};
    final Map<String, TextEditingController> amountCtrls = {};

    stockMap.forEach((k, v) {
      stockCtrls[k] = TextEditingController(text: v.toString());
      amountCtrls[k] = TextEditingController(
        text: amountMap[k]?.toString() ?? "0",
      );
    });

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Update Stock & Amount"),
        content: SingleChildScrollView(
          child: Column(
            children: stockMap.keys.map((size) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        size,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: stockCtrls[size],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Stock",
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: amountCtrls[size],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "₹ Amount",
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final updatedStock = <String, dynamic>{};
              final updatedAmount = <String, dynamic>{};

              stockCtrls.forEach((k, c) {
                updatedStock[k] = int.tryParse(c.text) ?? 0;
                updatedAmount[k] = double.tryParse(amountCtrls[k]!.text) ?? 0;
              });

              await TonicService().updateTonicStock(t['id'], {
                "stock": updatedStock,
                "amount": updatedAmount,
              });

              if (mounted) Navigator.pop(context);
              fetchTonics();
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Delete Tonic"),
        content: const Text("Are you sure you want to delete this tonic?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await TonicService().deleteTonic(id);
              if (mounted) Navigator.pop(context);
              fetchTonics();
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  /// ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                onChanged: search,
                decoration: InputDecoration(
                  hintText: "Search tonic name or code",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final t = filtered[i];
                    final days = daysLeft(t['expiryDate']);
                    final stockMap = toMap(t['stock']);
                    final amountMap = toMap(t['amount']);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// Header
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  t['tonicName'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor(
                                    days,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  days <= 30 ? "$days days left" : "Valid",
                                  style: TextStyle(
                                    color: statusColor(days),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Code: ${t['tonicCode']}",
                            style: const TextStyle(color: Colors.grey),
                          ),

                          const SizedBox(height: 16),

                          /// Stock header
                          Row(
                            children: const [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  "Size",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "Stock",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "Amount",
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(),

                          ...stockMap.keys.map((k) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      k,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      stockMap[k].toString(),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      "₹${amountMap[k]}",
                                      textAlign: TextAlign.end,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                          const Divider(height: 24),

                          /// Dates + actions
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Mfg: ${formatDate(t['manifacturingDate'])}",
                              ),
                              Text(
                                "Exp: ${formatDate(t['expiryDate'])}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: statusColor(days),
                                ),
                              ),
                            ],
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: primary),
                                onPressed: () => showUpdateDialog(t),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => confirmDelete(t['id']),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
