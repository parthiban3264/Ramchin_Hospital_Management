import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../Pages/NotificationsPage.dart';
import 'create_test_scan/service.dart';

class AddScanPage extends StatefulWidget {
  const AddScanPage({super.key});

  @override
  State<AddScanPage> createState() => _AddScanPageState();
}

class _AddScanPageState extends State<AddScanPage> {
  List<dynamic> allScans = [];
  bool isLoading = true;

  /// loading trackers
  int? loadingScanId;
  int? loadingOptionId;

  static const gold = Color(0xFFBF955E);

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    final res = await TestAndScanService().fetchAll();
    if (!mounted) return;

    setState(() {
      allScans = res.where((e) => e['type'] == 'SCAN').toList();
      isLoading = false;
    });
  }

  /// ================= SNACK =================
  void snack(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  /// ================= DELETE CONFIRM =================
  Future<bool> showDeleteConfirm(String title, {required int id}) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Confirm Delete"),
            content: Text("Are you sure you want to delete $title?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  bool res = false;

                  if (title == 'this scan') {
                    res = await TestAndScanService().deleteTestOrScan(id);
                  } else {
                    res = await TestAndScanService().deleteTestOrScanOption(id);
                  }

                  if (context.mounted) Navigator.pop(context, true);

                  if (res) {
                    init();
                  } else {
                    snack("Delete failed");
                  }
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// ================= TOGGLES =================
  void toggleScanStatus(int index, bool currentStatus) async {
    HapticFeedback.lightImpact();
    final id = allScans[index]['id'];

    setState(() => loadingScanId = id);

    final success = await TestAndScanService().updateStatus(id, !currentStatus);

    if (!mounted) return;

    setState(() => loadingScanId = null);

    if (success) {
      init();
    } else {
      snack("Failed to update scan status");
    }
  }

  void toggleOptionStatus(
    int scanIndex,
    int optIndex,
    bool currentStatus,
  ) async {
    HapticFeedback.lightImpact();
    final id = allScans[scanIndex]['options'][optIndex]['id'];

    setState(() => loadingOptionId = id);

    final success = await TestAndScanService().updateOptionStatus(
      id,
      !currentStatus,
    );

    if (!mounted) return;

    setState(() => loadingOptionId = null);

    if (success) {
      init();
    } else {
      snack("Failed to update option status");
    }
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          decoration: const BoxDecoration(
            color: gold,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
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
                  const Text(
                    "Scan Management",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationPage(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      /// ================= BODY =================
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : allScans.isEmpty
          ? _emptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: allScans.length,
              itemBuilder: (context, index) {
                final scan = allScans[index];
                final List options = scan['options'] ?? [];

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// ================= HEADER =================
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      scan['title'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Base Price ₹${scan['amount'] ?? 0}",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Chip(
                                label: Text(
                                  scan['isActive'] ? 'ACTIVE' : 'INACTIVE',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: scan['isActive']
                                    ? Colors.green
                                    : Colors.red,
                              ),

                              loadingScanId == scan['id']
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Switch(
                                      value: scan['isActive'] ?? true,
                                      activeColor: Colors.green,
                                      onChanged: (v) => toggleScanStatus(
                                        index,
                                        scan['isActive'] ?? true,
                                      ),
                                    ),

                              PopupMenuButton(
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                                onSelected: (v) async {
                                  if (v == 'delete') {
                                    final ok = await showDeleteConfirm(
                                      "this scan",
                                      id: scan['id'],
                                    );
                                    if (ok) init();
                                  }
                                },
                              ),
                            ],
                          ),

                          const Divider(height: 24),

                          /// ================= OPTIONS =================
                          ...List.generate(options.length, (optIndex) {
                            final option = options[optIndex];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          option['optionName'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "₹${option['price'] ?? 0}",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  loadingOptionId == option['id']
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Switch(
                                          value: option['isActive'] ?? true,
                                          activeColor: Colors.green,
                                          onChanged: (v) => toggleOptionStatus(
                                            index,
                                            optIndex,
                                            option['isActive'] ?? true,
                                          ),
                                        ),

                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      final ok = await showDeleteConfirm(
                                        "this option",
                                        id: option['id'],
                                      );
                                      if (ok) init();
                                    },
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_scanner, size: 60, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            "No scans available",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
