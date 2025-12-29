import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../Services/Medicine_Service.dart';

class ModifyMedicinePage extends StatefulWidget {
  const ModifyMedicinePage({super.key});

  @override
  State<ModifyMedicinePage> createState() => _ModifyMedicinePageState();
}

class _ModifyMedicinePageState extends State<ModifyMedicinePage> {
  List<Map<String, dynamic>> medicines = [];
  List<Map<String, dynamic>> filtered = [];
  bool loading = true;

  final searchController = TextEditingController();

  static const Color primary = Color(0xFFBF955E);
  static const Color bg = Color(0xFFF6F7FB);

  @override
  void initState() {
    super.initState();
    fetchMedicines();
  }

  Future<void> fetchMedicines() async {
    medicines = await MedicineService().getAllMedicines();
    filtered = medicines.where((m) => daysLeft(expiry(m)) >= 0).toList();
    setState(() => loading = false);
  }

  void search(String value) {
    filtered = medicines.where((m) {
      final name = (m['medicianName'] ?? '').toString().toLowerCase();
      final code = (m['medicianCode'] ?? '').toString().toLowerCase();
      final days = daysLeft(expiry(m));
      return days >= 0 &&
          (name.contains(value.toLowerCase()) ||
              code.contains(value.toLowerCase()));
    }).toList();
    setState(() {});
  }

  String? expiry(Map m) => m['expiryDate'] ?? m['expiry_date'] ?? m['expiry'];
  String? manufacture(Map m) =>
      m['manufacturingDate'] ?? m['manifacturingDate'];

  String formatDate(String? date) {
    if (date == null) return "-";
    final d = DateTime.tryParse(date);
    return d == null ? "-" : DateFormat("dd MMM yyyy").format(d);
  }

  int daysLeft(String? date) {
    if (date == null) return 999;
    final d = DateTime.tryParse(date);
    if (d == null) return 999;
    return d.difference(DateTime.now()).inDays;
  }

  Color statusColor(int days) => days <= 30 ? Colors.orange : Colors.green;
  String statusText(int days) => days <= 30 ? "$days days left" : "Valid";

  void showUpdateDialog(Map m) {
    final stockCtrl = TextEditingController(text: m['stock'].toString());
    final amountCtrl = TextEditingController(text: m['amount'].toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Update Medicine"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stockCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Stock"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Amount"),
            ),
          ],
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
              await MedicineService().updateMedicineStock(m['id'], {
                "stock": int.parse(stockCtrl.text),
                "amount": double.parse(amountCtrl.text),
              });
              if (mounted) Navigator.pop(context);
              fetchMedicines();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Medicine"),
        content: const Text("Are you sure you want to delete this medicine?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await MedicineService().deleteMedicine(id);
              if (mounted) Navigator.pop(context);
              fetchMedicines();
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

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
              // Search Bar
              TextField(
                controller: searchController,
                onChanged: search,
                decoration: InputDecoration(
                  hintText: "Search by name or code",
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

              // Empty state
              if (filtered.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.medical_services_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          "No valid medicines found",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              else
                // Medicine List
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final m = filtered[i];
                      final days = daysLeft(expiry(m));
                      final color = statusColor(days);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
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
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Name + Status
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    m['medicianName'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    statusText(days),
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Code / Stock / Amount
                            Text(
                              "Code: ${m['medicianCode'] ?? '-'}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Stock: ${m['stock']}",
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              "Amount: ₹${m['amount']}",
                              style: const TextStyle(fontSize: 14),
                            ),
                            const Divider(height: 24),

                            // Dates
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Manufactured",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      formatDate(manufacture(m)),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      "Expiry",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      formatDate(expiry(m)),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),

                            // Actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: primary),
                                  onPressed: () => showUpdateDialog(m),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => confirmDelete(m['id']),
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
