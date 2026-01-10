import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Pages/NotificationsPage.dart';
import '../../../Pages/payment_modal.dart';
import '../../../Services/Injection_Service.dart';
import '../../../Services/Medi_Tonic_Injection_service.dart';
import '../../../Services/Medicine_Service.dart';
import '../../../Services/Tonic_Service.dart';
import '../../../Services/consultation_service.dart';
import '../../../Services/payment_service.dart';
import '../../../Services/socket_service.dart';
import 'Widget/pdf_bill_service.dart';
import 'Widget/whatsapp_Bill.dart';

class MedicalFeePage extends StatefulWidget {
  final Map<String, dynamic> consultation;
  final int index;
  const MedicalFeePage({
    super.key,
    required this.consultation,
    required this.index,
  });

  @override
  State<MedicalFeePage> createState() => _MedicalFeePageState();
}

class _MedicalFeePageState extends State<MedicalFeePage> {
  late Map<String, dynamic> consultation;
  final Color primaryColor = const Color(0xFFBF955E);
  final socketService = SocketService();
  bool showAll = false;
  final MedicineService medicineService = MedicineService();
  bool _isLoading = false;
  bool paymentSuccess = false;

  late List medicines;
  late List injections;
  late List tonics;

  @override
  void initState() {
    super.initState();
    consultation = Map<String, dynamic>.from(widget.consultation);
    medicines = consultation['MedicinePatient'] ?? [];
    injections = consultation['InjectionPatient'] ?? [];
    tonics = consultation['TonicPatient'] ?? [];
    // Add a default selection flag
    for (var m in medicines) {
      m['selected'] = true;
    }
    for (var t in tonics) {
      t['selected'] = true;
    }
    for (var i in injections) {
      i['selected'] = true;
    }
    _updateTime();

    // Initialize medicine state
    for (var med in medicines) {
      med['doctorDays'] = (med['days'] ?? 1);
      med['currentDays'] = med['days'] ?? 1;
    }
  }

  String? _dateTime;
  void _updateTime() {
    setState(() {
      _dateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
    });
  }

  double get totalCharges =>
      _listTotal(medicines) + _listTotal(injections) + _listTotal(tonics);

  // double _listTotal(List items) {
  //   double sum = 0;
  //   for (var item in items) {
  //     final val = item['total'] ?? 0;
  //     sum += val is int ? val.toDouble() : val;
  //   }
  //   return sum;
  // }
  double _listTotal(List items) {
    double sum = 0;
    for (var item in items) {
      if (item['selected'] == true) {
        final val = item['total'] ?? 0;
        sum += val is int ? val.toDouble() : val;
      }
    }
    return sum;
  }

  // Future<void> updateMedicineStockAfterPayment(
  //   Map<String, dynamic> item,
  // ) async {
  //   if (item['selected'] != true) return;
  //
  //   final med = item['Medician'];
  //
  //   int medicineId = med['id'];
  //   int usedQty = (item['quantityNeeded'] as num).toInt();
  //   int oldStock = (med['stock'] as num).toInt(); // already given in response
  //
  //   int newStock = oldStock - usedQty;
  //
  //   await MedicineService().updateMedicineStock(medicineId, {
  //     "stock": newStock,
  //   });
  //

  // }
  // List<Map<String, dynamic>> stockItems = [];
  //
  // Future<bool> updateMedicineStockAfterPayment(
  //   Map<String, dynamic> item,
  //   BuildContext context,
  // ) async {
  //   if (item['selected'] != true) return true;
  //
  //   final med = item['Medician'];
  //   int medicineId = med['id'];
  //   int usedQty = (item['quantityNeeded'] as num).toInt();
  //   int oldStock = (med['stock'] as num).toInt();
  //   int newStock = oldStock - usedQty;
  //
  //   await MedicineService().updateMedicineStock(medicineId, {
  //     "stock": newStock,
  //   });

  //
  //   return true; // continue payment
  // }
  //
  // Future<bool> checkMedicineStock(
  //   Map<String, dynamic> item,
  //   BuildContext context,
  // ) async {
  //   final med = item['Medician'];
  //   int usedQty = (item['quantityNeeded'] as num).toInt();
  //   int oldStock = (med['stock'] as num).toInt();
  //   int newStock = oldStock - usedQty;
  //
  //   // Red warning → stop payment
  //   if (newStock < 0) {
  //     await stockDialogBox(
  //       context: context,
  //       title: "Stock Error",
  //       oldStock: oldStock,
  //       usedQty: usedQty,
  //       newStock: newStock,
  //       isWarning: false,
  //     );
  //     return false;
  //   }
  //
  //   // Yellow warning → continue payment
  //   if (newStock <= 5) {
  //     await stockDialogBox(
  //       context: context,
  //       title: "Low Stock Warning",
  //       oldStock: oldStock,
  //       usedQty: usedQty,
  //       newStock: newStock,
  //       isWarning: true,
  //     );
  //   }
  //
  //   return true;
  // }
  //
  // Future<void> updateInjectionStock(Map<String, dynamic> item) async {
  //   if (item['selected'] != true) return;
  //
  //   final inj = item['Injection'];
  //
  //   int injectionId = inj['id'];
  //   String dose = item['Doase']; // example "10IU"
  //   int qtyUsed = item['quantity']; // example 10
  //
  //   Map<String, dynamic> stockMap = Map<String, dynamic>.from(inj['stock']);
  //
  //   int oldStock = stockMap[dose] ?? 0;
  //   int newStock = oldStock - qtyUsed;
  //
  //   stockMap[dose] = newStock;
  //
  //   await InjectionService().updateInjectionStock(injectionId, {
  //     "stock": stockMap,
  //   });
  //
  // }
  //
  // Future<void> updateTonicStock(Map<String, dynamic> item) async {
  //   if (item['selected'] != true) return;
  //
  //   final tonic = item['Tonic'];
  //
  //   int tonicId = tonic['id'];
  //
  //   int quantityMl = item['quantity']; // Example = 250
  //   String stockKey = "${quantityMl}ml"; // "250ml"
  //
  //   Map<String, dynamic> stockMap = Map<String, dynamic>.from(tonic['stock']);
  //
  //   int oldStock = stockMap[stockKey] ?? 0;
  //
  //   // One tonic used = 1 bottle
  //   int usedQty = 1;
  //
  //   int newStock = oldStock - usedQty;
  //
  //   stockMap[stockKey] = newStock;
  //
  //   await TonicService().updateTonicStock(tonicId, {"stock": stockMap});
  //
  // }
  //
  // Future<void> checkTonicStock(
  //   Map<String, dynamic> item,
  //   BuildContext context,
  // ) async {
  //   final tonic = item['Tonic'];
  //
  //   int quantityMl = item['quantity']; // Example: 250
  //   String stockKey = "${quantityMl}ml"; // e.g., "250ml"
  //
  //   Map<String, dynamic> stockMap = Map<String, dynamic>.from(tonic['stock']);
  //   int oldStock = stockMap[stockKey] ?? 0;
  //
  //   // One tonic used = 1 bottle
  //   int newStock = oldStock - 1;
  //
  //   // Red warning if negative (cannot proceed)
  //   if (newStock < 0) {
  //     await stockDialogBox(
  //       context: context,
  //       title: "Stock Error",
  //       oldStock: oldStock,
  //       usedQty: 1,
  //       newStock: newStock,
  //       isWarning: false, // red
  //     );
  //     throw Exception("Tonic stock insufficient for ${stockKey}");
  //   }
  //
  //   // Yellow warning if stock <=5
  //   if (newStock <= 5) {
  //     await stockDialogBox(
  //       context: context,
  //       title: "Low Stock Warning",
  //       oldStock: oldStock,
  //       usedQty: 1,
  //       newStock: newStock,
  //       isWarning: true, // yellow
  //     );
  //   }
  //
  //   // Otherwise, just continue — do not decrease stock yet
  // }

  // ==================== STOCK UTILS ====================

  List<Map<String, dynamic>> buildStockItems({
    required List<Map<String, dynamic>> medicines,
    required List<Map<String, dynamic>> injections,
    required List<Map<String, dynamic>> tonics,
  }) {
    List<Map<String, dynamic>> stockItems = [];

    // ---------------------- MEDICINES ----------------------
    for (var med in medicines) {
      final medObj = med['Medician'] ?? {};
      int oldStock = (medObj['stock'] as num?)?.toInt() ?? 0;
      int usedQty = (med['quantityNeeded'] as num?)?.toInt() ?? 0;

      int remaining = oldStock - usedQty;

      stockItems.add({
        'type': 'Medicine',
        'name': medObj['medicianName'] ?? 'Unknown',
        // 'unit': med['quantity'] ?? '',
        'selected': med['selected'],
        'currentStock': oldStock,
        'usedQty': usedQty,
        'remainingStock': remaining,
        'isWarning': remaining <= 5 && remaining >= 0,
        'isError': remaining < 0,
      });
    }

    // ---------------------- INJECTIONS ----------------------
    for (var inj in injections) {
      final injObj = inj['Injection'] ?? {};
      Map<String, dynamic> stockMap = Map<String, dynamic>.from(
        injObj['stock'] ?? {},
      );
      String dose = inj['Doase'] ?? '';
      // int qtyUsed = (inj['quantity'] as num?)?.toInt() ?? 0;

      int oldStock = (stockMap[dose] as num?)?.toInt() ?? 0;
      int remaining = oldStock - 1;

      stockItems.add({
        'type': 'Injection',
        'name': injObj['injectionName'] ?? 'Unknown',
        'unit': dose,
        'selected': inj['selected'],
        'currentStock': oldStock,
        'usedQty': 1,
        'remainingStock': remaining,
        'isWarning': remaining <= 5 && remaining >= 0,
        'isError': remaining < 0,
      });
    }

    // ---------------------- TONICS ----------------------
    for (var tonic in tonics) {
      final tonicObj = tonic['Tonic'] ?? {};

      int quantityMl = (tonic['quantity'] as num?)?.toInt() ?? 0;
      String stockKey = "${quantityMl}ml";

      Map<String, dynamic> stockMap = Map<String, dynamic>.from(
        tonicObj['stock'] ?? {},
      );
      int oldStock = (stockMap[stockKey] as num?)?.toInt() ?? 0;

      int remaining = oldStock - 1;

      stockItems.add({
        'type': 'Tonic',
        'name': tonicObj['tonicName'] ?? 'Unknown',
        'unit': stockKey,
        'selected': tonic['selected'],
        'currentStock': oldStock,
        'usedQty': 1,
        'remainingStock': remaining,
        'isWarning': remaining <= 5 && remaining >= 0,
        'isError': remaining < 0,
      });
    }

    return stockItems;
  }

  Future<bool> checkStockAndShowDialog({
    required BuildContext context,
    required List<Map<String, dynamic>> medicines,
    required List<Map<String, dynamic>> injections,
    required List<Map<String, dynamic>> tonics,
  }) async {
    final stockItems = buildStockItems(
      medicines: medicines,
      injections: injections,
      tonics: tonics,
    );

    // ⚠ Show ONLY items that are selected + warning/error
    final filteredItems = stockItems
        .where(
          (item) =>
              item['selected'] == true &&
              (item['isError'] == true || item['isWarning'] == true),
        )
        .toList();

    // 🟢 No warning & No error → Directly allow payment
    if (filteredItems.isEmpty) {
      return true;
    }

    // 🔴 If any error exists → user MUST see dialog
    bool hasError = filteredItems.any((item) => item['isError'] == true);

    // 🔥 Show Dialog only when needed
    await showMultiStockDialog(
      context: context,
      title: hasError ? "Stock Error" : "Stock Warning",
      items: filteredItems,
      onNotify: () {},
    );

    // ❌ If error exists → cannot proceed
    return !hasError;
  }

  Future<void> updateStockAfterPayment({
    required List<Map<String, dynamic>> medicines,
    required List<Map<String, dynamic>> injections,
    required List<Map<String, dynamic>> tonics,
  }) async {
    // Medicines
    for (var med in medicines) {
      if (med['selected'] != true) continue;

      final stock = ((med['Medician']['stock'] ?? 0) as num).toInt();
      final used = ((med['quantityNeeded'] ?? 0) as num).toInt();
      final newStock = stock - used;

      await MedicineService().updateMedicineStock(med['Medician']['id'], {
        "stock": newStock,
      });
    }

    // Injections
    for (var inj in injections) {
      if (inj['selected'] != true) continue;

      Map<String, dynamic> stockMap = Map<String, dynamic>.from(
        inj['Injection']['stock'] ?? {},
      );

      String dose = inj['Doase'] ?? "";
      // int qtyUsed = ((inj['quantity'] ?? 0) as num).toInt();

      int current = ((stockMap[dose] ?? 0) as num).toInt();
      int newStock = current - 1;

      stockMap[dose] = newStock;

      await InjectionService().updateInjectionStock(inj['Injection']['id'], {
        "stock": stockMap,
      });
    }
    // for (var inj in injections) {
    //   if (inj['selected'] != true) continue;
    //
    //   // Convert stock to editable map
    //   Map<String, dynamic> stockMap = Map<String, dynamic>.from(
    //     inj['Injection']['stock'] ?? {},
    //   );
    //
    //   String dose = inj['Doase'] ?? "";
    //   int qtyUsed = ((inj['quantity'] ?? 0) as num).toInt();
    //
    //   // Extract numerical part of dose: "10IU" → 10
    //   int doseValue = int.tryParse(dose.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    //
    //   // Calculate vials used
    //   int vialsUsed = (qtyUsed / doseValue).ceil();
    //
    //   // Fetch current stock for that dose
    //   int current = ((stockMap[dose] ?? 0) as num).toInt();
    //
    //   // Calculate new stock
    //   int newStock = current - vialsUsed;
    //
    //   // Update map
    //   stockMap[dose] = newStock;
    //
    //   // Send update to backend
    //   await InjectionService().updateInjectionStock(inj['Injection']['id'], {
    //     "stock": stockMap,
    //   });
    //

    // }

    // Tonics
    for (var tonic in tonics) {
      if (tonic['selected'] != true) continue;

      Map<String, dynamic> stockMap = Map<String, dynamic>.from(
        tonic['Tonic']['stock'] ?? {},
      );

      final stockKey = "${tonic['quantity']}ml";

      int current = ((stockMap[stockKey] ?? 0) as num).toInt();
      int newStock = current - 1;

      stockMap[stockKey] = newStock;

      await TonicService().updateTonicStock(tonic['Tonic']['id'], {
        "stock": stockMap,
      });
    }
  }

  // ==================== STOCK DIALOG ====================

  Future<void> showMultiStockDialog({
    required BuildContext context,
    required String title,
    required List<Map<String, dynamic>> items,
    required VoidCallback onNotify,
  }) async {
    final filteredItems = items
        .where(
          (it) =>
              (it['isError'] == true || it['isWarning'] == true) &&
              (it['selected'] == true),
        )
        .toList();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Container(
          width: 420, // 🔥 FIXED WIDTH
          height: 500, // 🔥 FIXED HEIGHT
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ---------------- HEADER ----------------
              Row(
                children: [
                  Icon(Icons.inventory_rounded, color: Colors.blue, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(height: 1, thickness: 1.2),

              const SizedBox(height: 12),

              // ---------------- LIST AREA (SCROLLABLE) ----------------
              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  radius: const Radius.circular(10),
                  child: filteredItems.isEmpty
                      ? Center(
                          child: Text(
                            "No low stock or error items.",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: filteredItems.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, index) {
                            final item = filteredItems[index];
                            final isError = item['isError'] == true;
                            // final isWarning = item['isWarning'] == true;

                            final Color color = isError
                                ? Colors.red
                                : Colors.orange;

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.6),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title
                                  (item['type'] != 'Medicine')
                                      ? Text(
                                          "${item['type']} — ${item['name']} (${item['unit']})",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: color,
                                          ),
                                        )
                                      : Text(
                                          "${item['type']} — ${item['name']}",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: color,
                                          ),
                                        ),
                                  const SizedBox(height: 8),

                                  // Stock info
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Current: ${item['currentStock']}",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        "Need: ${item['usedQty']}",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      // Text(
                                      //   "Remaining: ${item['remainingStock']}",
                                      //   style: const TextStyle(
                                      //     fontSize: 14,
                                      //     fontWeight: FontWeight.w600,
                                      //   ),
                                      // ),
                                    ],
                                  ),

                                  const SizedBox(height: 10),

                                  // Warning/Error text
                                  Text(
                                    isError
                                        ? "❌ Stock insufficient!"
                                        : "⚠ Stock running low!",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),

              const SizedBox(height: 14),

              // ---------------- ACTION BUTTONS ----------------
              Row(
                children: [
                  // NOTIFY
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.notifications_active,
                        color: Colors.white,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        onNotify();
                      },
                      label: const Text(
                        "Notify",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // OK
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        "OK",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateStatus() async {
    if (_isLoading) return; // prevent double-tap

    setState(() => _isLoading = true);

    final consultationId = consultation['id'];

    // 3️⃣ Check consultation flags
    final bool injection = consultation['Injection'] ?? false;
    final bool scanningTesting = consultation['scanningTesting'] ?? false;

    String newStatus;
    String userMessage;

    if (!injection && !scanningTesting) {
      newStatus = 'COMPLETED';
      userMessage = 'Consultation completed successfully!';
    } else {
      newStatus = 'ENDPROCESSING';
      userMessage = 'Medical Fee completed.';
    }

    try {
      // await _medicineService.updateMedicineStock() {
      // }
      await ConsultationService().updateConsultation(consultationId, {
        'status': newStatus,
        'medicineTonic': false,
        'updatedAt': _dateTime.toString(),
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(userMessage)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> updateMedicationStatus() async {
    try {
      final service = MedicineTonicInjectionService();

      // Update medicines
      for (var item in medicines) {
        await service.updateMedicationRecord(
          type: "medicine",
          id: item["id"],
          data: {
            "status": item["selected"] == true ? "COMPLETED" : "CANCELLED",
            "reduceDays": item['currentDays'],
            "reduceQuantity": item['quantityNeeded'],
            "paymentStatus": true,
            "total": item['total'],
            "updatedAt": _dateTime.toString(),
          },
        );
      }
      // for (var item in medicines) {

      //
      //   final int reduceDays =
      //       int.tryParse(item['currentDays'].toString()) ?? 0;
      //   final int reduceQuantity =
      //       int.tryParse(item['quantityNeeded'].toString()) ?? 0;
      //   final double total = double.tryParse(item['total'].toString()) ?? 0;
      //
      //   await service.updateMedicationRecord(
      //     type: "medicine",
      //     id: item["id"],
      //     data: {
      //       "status": item["selected"] ? "COMPLETED" : "CANCELLED",
      //       "reduceDays": reduceDays,
      //       "reduceQuantity": reduceQuantity,
      //       "paymentStatus": true,
      //       "total": total,
      //       "updatedAt": _dateTime.toString(),
      //     },
      //   );
      // }

      // Update injections
      for (var item in injections) {
        await service.updateMedicationRecord(
          type: "injection",
          id: item["id"],
          data: {
            "status": item["selected"] == true ? "COMPLETED" : "CANCELLED",
            "paymentStatus": true,
            "updatedAt": _dateTime.toString(),
          },
        );
      }

      // Update tonics
      for (var item in tonics) {
        await service.updateMedicationRecord(
          type: "tonic",
          id: item["id"],
          data: {
            "status": item["selected"] == true ? "COMPLETED" : "CANCELLED",
            "reduceQuantity": item['quantity'],
            "paymentStatus": true,
            "total": item['total'],
            "updatedAt": _dateTime.toString(),
          },
        );
      }
    } catch (e) {
      throw Exception("Failed updating medication status");
    }
  }

  // void _showHandlePayment() async {
  //   if (_isLoading) return; // Prevent double payment clicks
  //   setState(() => _isLoading = true);
  //
  //   try {
  //
  //
  //     final consultationId = consultation['id'];
  //
  //     int? paymentId;
  //     if (consultation['MedicinePatient'] != null &&
  //         consultation['MedicinePatient'].isNotEmpty) {
  //       paymentId = consultation['MedicinePatient'][0]['payment_Id'];
  //     } else if (consultation['InjectionPatient'] != null &&
  //         consultation['InjectionPatient'].isNotEmpty) {
  //       paymentId = consultation['InjectionPatient'][0]['payment_Id'];
  //     } else if (consultation['TonicPatient'] != null &&
  //         consultation['TonicPatient'].isNotEmpty) {
  //       paymentId = consultation['TonicPatient'][0]['payment_Id'];
  //     }
  //
  //     if (paymentId == null) {
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(const SnackBar(content: Text('Payment ID not found')));
  //       return;
  //     }
  //
  //     // for (var item in medicines) {
  //     //   await updateMedicineStockAfterPayment(item, context);
  //     // }
  //     for (var item in medicines) {
  //       bool continuePayment = await updateMedicineStockAfterPayment(
  //         item,
  //         context,
  //       );
  //       if (!continuePayment) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('Payment cancelled due to stock error.'),
  //             backgroundColor: Colors.red,
  //           ),
  //         );
  //         return; // stop payment flow
  //       }
  //     }
  //
  //     for (var item in tonics) {
  //       await updateTonicStock(item);
  //     }
  //     // for (var item in injections) {
  //     //   await updateInjectionStock(item);
  //     // }
  //
  //
  //
  //     // 💳 Open payment modal (disable loading while waiting for dialog)
  //     setState(() => _isLoading = false);
  //     final paymentResult = await showDialog<Map<String, dynamic>>(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (_) => PaymentModal(registrationFee: totalCharges),
  //     );
  //
  //     // If user cancels payment
  //     if (paymentResult == null) {
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(const SnackBar(content: Text('Payment cancelled')));
  //       return;
  //     }
  //
  //     // Continue after dialog closes
  //     setState(() => _isLoading = true);
  //
  //     final String paymentMode = paymentResult['paymentMode'] ?? 'unknown';
  //     final staffId = await secureStorage.read(key: 'userId');
  //
  //     // 1️⃣ Update only the amount first
  //     await PaymentService().updatePayment(paymentId, {'amount': totalCharges});
  //
  //     // 2️⃣ Then mark payment as PAID
  //     await PaymentService().updatePayment(paymentId, {
  //       'status': 'PAID',
  //       'staff_Id': staffId.toString(),
  //       'paymentType': paymentMode,
  //       'updatedAt': _dateTime.toString(),
  //     });
  //
  //     if (mounted) {
  //       setState(() {
  //         paymentSuccess = true;
  //       });
  //
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Payment successful!'),
  //           backgroundColor: Colors.green,
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Medical Payment failed: $e'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   } finally {
  //     if (mounted) setState(() => _isLoading = false);
  //   }
  // }
  // void _showHandlePayment() async {
  //   if (_isLoading) return;
  //   setState(() => _isLoading = true);
  //
  //   try {
  //     final consultationId = consultation['id'];
  //
  //     int? paymentId;
  //     if (consultation['MedicinePatient'] != null &&
  //         consultation['MedicinePatient'].isNotEmpty) {
  //       paymentId = consultation['MedicinePatient'][0]['payment_Id'];
  //     } else if (consultation['InjectionPatient'] != null &&
  //         consultation['InjectionPatient'].isNotEmpty) {
  //       paymentId = consultation['InjectionPatient'][0]['payment_Id'];
  //     } else if (consultation['TonicPatient'] != null &&
  //         consultation['TonicPatient'].isNotEmpty) {
  //       paymentId = consultation['TonicPatient'][0]['payment_Id'];
  //     }
  //
  //     if (paymentId == null) {
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(const SnackBar(content: Text('Payment ID not found')));
  //       return;
  //     }
  //
  //     // 1️⃣ Check stock first without decreasing
  //     for (var item in medicines) {
  //       bool canProceed = await checkMedicineStock(item, context);
  //       if (!canProceed) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('Payment cancelled due to stock error.'),
  //             backgroundColor: Colors.red,
  //           ),
  //         );
  //         return;
  //       }
  //     }
  //
  //     for (var item in tonics) {
  //       try {
  //         await checkTonicStock(item, context); // will show warning dialogs
  //       } catch (e) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('Payment cancelled due to tonic stock error.'),
  //             backgroundColor: Colors.red,
  //           ),
  //         );
  //         return; // stop payment flow
  //       }
  //     }
  //
  //     setState(() => _isLoading = false);
  //
  //     // 2️⃣ Show payment modal
  //     final paymentResult = await showDialog<Map<String, dynamic>>(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (_) => PaymentModal(registrationFee: totalCharges),
  //     );
  //
  //     if (paymentResult == null) {
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(const SnackBar(content: Text('Payment cancelled')));
  //       return; // do not decrease stock
  //     }
  //
  //     // 3️⃣ Payment successful → update payment and decrease stock
  //     setState(() => _isLoading = true);
  //     final String paymentMode = paymentResult['paymentMode'] ?? 'unknown';
  //     final staffId = await secureStorage.read(key: 'userId');
  //
  //     await PaymentService().updatePayment(paymentId, {'amount': totalCharges});
  //     await PaymentService().updatePayment(paymentId, {
  //       'status': 'PAID',
  //       'staff_Id': staffId.toString(),
  //       'paymentType': paymentMode,
  //       'updatedAt': _dateTime.toString(),
  //     });
  //
  //     // 4️⃣ Now decrease stock
  //     for (var item in medicines) {
  //       await updateMedicineStockAfterPayment(item, context);
  //     }
  //     for (var item in tonics) {
  //       await updateTonicStock(item);
  //     }
  //
  //     if (mounted) {
  //       setState(() => paymentSuccess = true);
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Payment successful!'),
  //           backgroundColor: Colors.green,
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Medical Payment failed: $e'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   } finally {
  //     if (mounted) setState(() => _isLoading = false);
  //   }
  // }
  // ==================== PAYMENT HANDLER ====================

  void _showHandlePayment() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // final consultationId = consultation['id'];
      int? paymentId;

      if (consultation['MedicinePatient']?.isNotEmpty ?? false) {
        paymentId = consultation['MedicinePatient'][0]['payment_Id'];
      } else if (consultation['InjectionPatient']?.isNotEmpty ?? false) {
        paymentId = consultation['InjectionPatient'][0]['payment_Id'];
      } else if (consultation['TonicPatient']?.isNotEmpty ?? false) {
        paymentId = consultation['TonicPatient'][0]['payment_Id'];
      }

      if (paymentId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Payment ID not found')));
        return;
      }

      // 1️⃣ Check stock for all items in a single dialog
      bool canProceed = await checkStockAndShowDialog(
        context: context,
        medicines: (medicines).cast<Map<String, dynamic>>(),
        injections: (injections).cast<Map<String, dynamic>>(),
        tonics: (tonics).cast<Map<String, dynamic>>(),
      );

      if (!canProceed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment cancelled due to stock error.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isLoading = false);

      // 2️⃣ Show payment modal
      Map<String, dynamic>? paymentResult;
      if (mounted) {
        paymentResult = await showDialog<Map<String, dynamic>>(
          context: context,
          barrierDismissible: false,
          builder: (_) => PaymentModal(registrationFee: totalCharges),
        );
      }

      if (paymentResult == null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Payment cancelled')));
        return;
      }

      setState(() => _isLoading = true);
      final prefs = await SharedPreferences.getInstance();
      final String paymentMode = paymentResult?['paymentMode'] ?? 'unknown';
      final staffId = prefs.getString('userId');

      await PaymentService().updatePayment(paymentId, {'amount': totalCharges});
      await PaymentService().updatePayment(paymentId, {
        'status': 'PAID',
        'staff_Id': staffId.toString(),
        'paymentType': paymentMode,
        'updatedAt': _dateTime.toString(),
      });

      // 3️⃣ Update stock after payment
      await updateStockAfterPayment(
        medicines: (medicines).cast<Map<String, dynamic>>(),
        injections: (injections).cast<Map<String, dynamic>>(),
        tonics: (tonics).cast<Map<String, dynamic>>(),
      );

      if (mounted) {
        setState(() => paymentSuccess = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful!'),
            backgroundColor: Colors.green,
          ),
        );
        await updateMedicationStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Medical Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = consultation['Patient'] ?? {};
    final doctor = consultation['Doctor'] ?? {};
    final drAllocatedDays =
        (consultation['MedicinePatient'] != null &&
            consultation['MedicinePatient'].isNotEmpty)
        ? consultation['MedicinePatient'][0]['days'] ?? 1
        : 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: paymentSuccess
                        ? null
                        : () => Navigator.pop(context),
                  ),
                  const Text(
                    "Medical Bill",
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
                  IconButton(
                    icon: const Icon(Icons.home, color: Colors.white),
                    onPressed: () {
                      int count = 0;
                      Navigator.popUntil(context, (route) => count++ >= 2);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),

        child: paymentSuccess || widget.index == 1
            ? _buildPaidBillView(patient, doctor)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPatientCard(patient, doctor),
                  const SizedBox(height: 18),
                  _buildMedicineTable(drAllocatedDays),
                  const SizedBox(height: 18),
                  _buildTonicTable(),
                  const SizedBox(height: 18),
                  _buildInjectionTable(),
                  const SizedBox(height: 20),

                  _buildBillSummaryCard(patient),

                  const SizedBox(height: 30),
                ],
              ),
      ),
    );
  }

  // -------------------- PATIENT CARD --------------------
  Widget _buildPatientCard(Map patient, Map doctor) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: primaryColor),
                const SizedBox(width: 8),
                const Text(
                  "Patient Details",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ],
            ),
            const Divider(thickness: 0.8, height: 22),
            Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                _info("Patient ID", consultation['patient_Id']),
                _info("Name", patient['name']),
                _info("Phone", patient['phone']?['mobile']),
                _info("Address", patient['address']?['Address']),
              ],
            ),
            if (showAll) ...[
              const Divider(thickness: 0.8, height: 22),
              const Text(
                "Consultation Details",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 6),
              _info("Doctor", doctor['name']),
              _info("Specialist", doctor['specialist']),
              _info("Purpose", consultation['purpose']),
              _info("Status", consultation['status']),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => showAll = !showAll),
                icon: Icon(
                  showAll ? Icons.expand_less : Icons.expand_more,
                  color: primaryColor,
                ),
                label: Text(
                  showAll ? "Hide Details" : "Show More",
                  style: TextStyle(color: primaryColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------- MEDICINE TABLE -------------------
  Widget _buildMedicineTable(int doctorDaysLimit) {
    if (medicines.isEmpty) return SizedBox();

    return _buildTableCard(
      title: "Medicines",
      icon: Icons.medical_services,
      columns: const [
        "Select",
        "Medicine",
        "Days",
        // "Per/Sesh",
        // "Eat",
        // "Session",
        "Total Qty",
        "Price",
        "Total",
      ],
      rows: medicines.map((med) {
        final name = med['Medician']?['medicianName'] ?? "Medicine";

        // Quantity per time (can be decimal)
        final qtyPerTime = double.tryParse(med['quantity'].toString()) ?? 0;

        // Doctor’s allocated days
        final doctorMaxDays = med['days'] ?? doctorDaysLimit;

        // User’s current selection (default = doctor’s limit)
        final currentDays = med['currentDays'] ?? doctorMaxDays;

        // Count how many sessions (M / A / N)
        int sessionCount = 0;
        if (med['morning'] == true) sessionCount++;
        if (med['afternoon'] == true) sessionCount++;
        if (med['night'] == true) sessionCount++;

        // Daily dose = qtyPerTime * sessionCount
        final qtyPerDay = qtyPerTime * sessionCount;

        // Total quantity = qtyPerDay * currentDays (rounded up)
        final totalQty = (qtyPerDay * currentDays).ceilToDouble();

        final price =
            double.tryParse(med['Medician']?['amount'].toString() ?? "0") ?? 0;
        final total = totalQty * price;

        // final afterEat = med['afterEat'] == true ? "AF" : "BF";
        // final sessions = [
        //   if (med['morning'] == true) "M",
        //   if (med['afternoon'] == true) "AF",
        //   if (med['night'] == true) "N",
        // ].join(", ");

        return [
          _selectToggleButton(med),
          name,
          _dayControls(med, doctorMaxDays),
          // qtyPerTime.toStringAsFixed(1),
          // afterEat,
          // sessions.isEmpty ? "—" : sessions,
          totalQty.toStringAsFixed(0),
          "₹ ${price.toStringAsFixed(1)}",
          "₹ ${total.toStringAsFixed(1)}",
        ];
      }).toList(),
    );
  }

  // -------------------- DAY CONTROLS --------------------
  Widget _dayControls(Map<String, dynamic> med, int doctorMaxDays) {
    int currentDays = med['currentDays'] ?? doctorMaxDays;
    int allowedMax = med['allowedMax'] ?? doctorMaxDays;

    bool canDec = currentDays > 1;
    bool canInc = currentDays < allowedMax;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
          onPressed: canDec
              ? () => _updateDays(med, currentDays - 1, doctorMaxDays)
              : null,
        ),
        Text(
          currentDays.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        IconButton(
          icon: Icon(
            Icons.add_circle,
            color: canInc ? Colors.green : Colors.grey,
          ),
          onPressed: canInc
              ? () => _updateDays(med, currentDays + 1, doctorMaxDays)
              : null,
        ),
      ],
    );
  }

  // -------------------- UPDATE DAYS --------------------
  void _updateDays(Map<String, dynamic> med, int newDays, int doctorMaxDays) {
    int allowedMax = med['allowedMax'] ?? doctorMaxDays;
    if (newDays < 1 || newDays > allowedMax) return;

    setState(() {
      med['currentDays'] = newDays;
      if (newDays > allowedMax) {
        med['allowedMax'] = newDays; // lock future increases
      }

      // Sessions count
      int sessionCount = 0;
      if (med['morning'] == true) sessionCount++;
      if (med['afternoon'] == true) sessionCount++;
      if (med['night'] == true) sessionCount++;

      final qtyPerTime = double.tryParse(med['quantity'].toString()) ?? 0;
      final qtyPerDay = qtyPerTime * sessionCount;

      // Calculate total qty rounded up
      final totalQty = (qtyPerDay * newDays).ceilToDouble();

      final price =
          double.tryParse(med['Medician']?['amount'].toString() ?? "0") ?? 0;

      med['quantityNeeded'] = totalQty;
      med['total'] = totalQty * price;
    });
  }

  // -------------------- TONIC TABLE --------------------
  Widget _buildTonicTable() {
    if (tonics.isEmpty) return SizedBox();

    return _buildTableCard(
      title: "Tonics",
      icon: Icons.local_drink,
      columns: const [
        "Select",
        "Tonic",
        "Qty",
        "Price",
        // "After Eat",
        // "Session",
      ],
      rows: tonics.map((tonic) {
        final name = tonic['Tonic']?['tonicName'] ?? "Tonic";
        final qty = (tonic['quantity'] ?? 0).toDouble();
        final total = (tonic['total'] ?? 0).toDouble();
        // final afterEat = tonic['afterEat'] == true ? "AF" : "BF";
        // final sessions = [
        //   if (tonic['morning'] == true) "M",
        //   if (tonic['afternoon'] == true) "AF",
        //   if (tonic['night'] == true) "N",
        // ].join(", ");
        return [
          _selectToggleButton(tonic),
          name,
          "${qty.toStringAsFixed(0)} ML",
          "₹ ${total.toStringAsFixed(1)}",
          // afterEat,
          // sessions.isEmpty ? "—" : sessions,
        ];
      }).toList(),
    );
  }

  // -------------------- INJECTION TABLE --------------------
  Widget _buildInjectionTable() {
    // if (injections.isEmpty) return _emptyCard("No injections prescribed.");
    if (injections.isEmpty) return SizedBox();

    return _buildTableCard(
      title: "Injections",
      icon: Icons.vaccines,
      columns: const ["Select", "Injection", "Qty", "Price"],
      rows: injections.map((inj) {
        final name = inj['Injection']?['injectionName'] ?? "Injection";
        final qty = (inj['quantity'] ?? 0).toDouble();
        double price = 0;
        // if (inj['Injection']?['amount'] is Map) {
        //   final amounts = Map<String, dynamic>.from(inj['Injection']['amount']);
        //   if (amounts.isNotEmpty) price = amounts.values.first.toDouble();
        // }
        if (inj['Injection']?['amount'] is Map && inj['Doase'] != null ||
            inj['quantity'] != null) {
          final amounts = Map<String, dynamic>.from(inj['Injection']['amount']);
          final dose = inj['Doase']; // e.g. "10IU"

          if (amounts.containsKey(dose)) {
            price = amounts[dose].toDouble();
          }
        }

        return [
          _selectToggleButton(inj),
          name,
          "${qty.toStringAsFixed(0)} ML/IU",
          "₹ ${price.toStringAsFixed(1)}",
        ];
      }).toList(),
    );
  }

  // -------------------- TABLE TEMPLATE --------------------
  Widget _buildTableCard({
    required String title,
    required IconData icon,
    required List<String> columns,
    required List<List<dynamic>> rows,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Row
            Row(
              children: [
                Icon(icon, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            // Table with horizontal scroll
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                border: TableBorder(
                  top: BorderSide(color: Colors.grey.shade300, width: 1),
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                  left: BorderSide(color: Colors.grey.shade300, width: 1),
                  right: BorderSide(color: Colors.grey.shade300, width: 1),
                  verticalInside: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1.2,
                  ),
                  horizontalInside: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1.2,
                  ),
                ),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                // Column widths adapt to content
                columnWidths: Map.fromIterables(
                  List.generate(columns.length, (index) => index),
                  List.generate(
                    columns.length,
                    (_) => const IntrinsicColumnWidth(),
                  ),
                ),
                children: [
                  // Table Header
                  TableRow(
                    decoration: BoxDecoration(color: Colors.blueGrey.shade200),
                    children: columns.map((col) {
                      return Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          col,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),
                  // Table Rows
                  ...rows.map((cells) {
                    return TableRow(
                      children: cells.map((cell) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: cell is Widget ? cell : Text(cell.toString()),
                        );
                      }).toList(),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectToggleButton(Map item) {
    bool selected = item['selected'] ?? true;
    return Material(
      elevation: 4, // gives shadow/elevation
      shape: const CircleBorder(), // makes it circular
      color: selected ? Colors.green : Colors.red,
      child: InkWell(
        customBorder: const CircleBorder(), // ripple effect within circle
        onTap: () {
          setState(() {
            item['selected'] = !selected;
          });
        },
        child: SizedBox(
          width: 32, // slightly bigger for better tap area
          height: 32,
          child: Center(
            child: Icon(
              selected ? Icons.check : Icons.close,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaidBillView(Map patient, Map doctor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPatientCard(patient, doctor),
        const SizedBox(height: 15),
        _buildBillSummaryCard(patient), // New summary section
      ],
    );
  }

  // -------------------- BILL SUMMARY --------------------

  Widget _buildBillSummaryCard(Map patient) {
    final patientName = patient['name'] ?? '';
    final phoneNumber = patient['phone']?['mobile'] ?? '';
    final selectedMedicines = medicines
        .where((m) => m['selected'] == true && m['status'] != 'CANCELLED')
        .toList();

    // for (var m in medicines) {}

    final selectedTonics = tonics
        .where((t) => t['selected'] == true && t['status'] != 'CANCELLED')
        .toList();
    final selectedInjections = injections
        .where((i) => i['selected'] == true && i['status'] != 'CANCELLED')
        .toList();

    if (paymentSuccess || widget.index == 1) {
      // ✅ Prescription Bill layout shown after payment success
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: const Text(
                  "Prescription Bill",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Divider(height: 22, thickness: 1),

              // 🔹 Medicines
              if (selectedMedicines.isNotEmpty) ...[
                const Text(
                  "Medicines",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 6),
                _buildSimpleTable(
                  headers: ["Name", "Qty", "Amount"],
                  rows: selectedMedicines.map((m) {
                    final name = m['Medician']?['medicianName'] ?? "Medicine";
                    final qty = (m['quantityNeeded'] ?? 0).toString();
                    final amt = (m['total'] ?? 0).toStringAsFixed(1);
                    return [name, qty, "₹ $amt"];
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],

              // 🔹 Tonics
              if (selectedTonics.isNotEmpty) ...[
                const Text(
                  "Tonics",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 6),
                _buildSimpleTable(
                  headers: ["Name", "Qty", "Amount"],
                  rows: selectedTonics.map((t) {
                    final name = t['Tonic']?['tonicName'] ?? "Tonic";
                    final qty = (t['quantity'] ?? 0).toString();
                    final amt = (t['total'] ?? 0).toStringAsFixed(1);
                    return [name, "${qty}ml", "₹ $amt"];
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],

              // 🔹 Injections
              if (selectedInjections.isNotEmpty) ...[
                const Text(
                  "Injections",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 6),
                _buildSimpleTable(
                  headers: ["Name", "Qty", "Amount"],
                  rows: selectedInjections.map((i) {
                    final name =
                        i['Injection']?['injectionName'] ?? "Injection";
                    final qty = (i['Doase'] ?? 0).toString();
                    // double price = 0;
                    // if (i['Injection']?['amount'] is Map) {
                    //   final amounts = Map<String, dynamic>.from(
                    //     i['Injection']['amount'],
                    //   );
                    //   if (amounts.isNotEmpty) {
                    //     price = amounts.values.first.toDouble();
                    //   }
                    // }
                    final amt = (i['total'] ?? 0).toStringAsFixed(1);

                    return [name, qty, "₹ $amt"];
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],

              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Status",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  Text(
                    "PAID",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ✅ Buttons
              Align(
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const FaIcon(
                        FontAwesomeIcons.whatsapp,
                        color: Colors.white,
                        size: 26,
                      ),
                      label: const Text(
                        "Send ",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => WhatsAppBillService.sendBill(
                        phoneNumber: phoneNumber,
                        patientName: patientName,
                        allConsultation: widget.consultation,
                        //totalAmount: 100,
                        medicines: medicines,
                        tonics: tonics,
                        injections: injections,
                        totalAmount: totalCharges,
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () => PdfBillService.pdfBill(
                        //phoneNumber: phoneNumber,
                        patientName: patientName,
                        allConsultation: widget.consultation,
                        totalAmount: totalCharges,
                        medicines: selectedMedicines,
                        tonics: selectedTonics,
                        injections: selectedInjections,
                      ),
                      icon: FaIcon(
                        FontAwesomeIcons.share,
                        color: Colors.white,
                        size: 18,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Spacer(),
                    ElevatedButton.icon(
                      icon: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle, color: Colors.white),
                      label: Text(
                        _isLoading ? "Updating..." : "OK ",

                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isLoading ? null : _updateStatus,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    // 🧾 Regular bill before payment
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: const Text(
                "Bill Summary",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Colors.black87,
                ),
              ),
            ),
            const Divider(height: 20),
            if (medicines.isNotEmpty) ...[
              _info(
                "Medicines Total",
                "₹ ${_listTotal(medicines).toStringAsFixed(1)}",
              ),
            ],
            if (tonics.isNotEmpty) ...[
              _info(
                "Tonics Total",
                "₹ ${_listTotal(tonics).toStringAsFixed(1)}",
              ),
            ],
            if (injections.isNotEmpty) ...[
              _info(
                "Injections Total",
                "₹ ${_listTotal(injections).toStringAsFixed(1)}",
              ),
            ],
            const Divider(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Grand Total",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                ),
                Text(
                  "₹ ${totalCharges.toStringAsFixed(1)}",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton.icon(
                onPressed: (_isLoading || totalCharges == 0)
                    ? null
                    : _showHandlePayment,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.payment, color: Colors.white),
                label: Text(
                  _isLoading ? "Processing..." : " Pay Now ",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_isLoading || totalCharges == 0)
                      ? Colors
                            .grey // disabled gray color
                      : primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleTable({
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300, width: 1),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade200),
          children: headers
              .map(
                (h) => Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    h,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        ...rows.map(
          (r) => TableRow(
            children: r
                .map(
                  (cell) => Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      cell.toString(),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  // -------------------- INFO & EMPTY --------------------
  Widget _info(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            "$label :",
            style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              (value?.toString().trim().isEmpty ?? true)
                  ? "—"
                  : value.toString(),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 14.5,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _emptyCard(String message) {
  //   return Card(
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  //     elevation: 2,
  //     child: Padding(
  //       padding: const EdgeInsets.all(28),
  //       child: Center(
  //         child: Text(
  //           message,
  //           style: const TextStyle(color: Colors.grey, fontSize: 14),
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
