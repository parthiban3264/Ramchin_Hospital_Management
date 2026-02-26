import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Pages/NotificationsPage.dart';
import '../../../Pages/payment_modal.dart';
import '../../../Services/Medi_Tonic_Injection_service.dart';
import '../../../Services/Medicine_Service.dart';
import '../../../Services/consultation_service.dart';
import '../../../Services/payment_service.dart';
import '../../../Services/socket_service.dart';
import 'Widget/medical_bill_pdf.dart';
import 'Widget/pdf_bill_service.dart';
import 'Widget/whatsapp_Bill.dart';
import '../../../Services/prescription_service.dart';

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

    // medicines = consultation['MedicinePatient'] ?? [];
    // injections = consultation['InjectionPatient'] ?? [];
    // tonics = consultation['TonicPatient'] ?? [];
    medicines = _normalizeMedicines(getAllPrescriptionMedicines());
    // medicines = getAllPrescriptionMedicines();
    injections = [];
    tonics = [];

    // Add a default selection flag
    // for (var m in medicines) {
    //   m['selected'] = true;
    // }
    // for (var t in tonics) {
    //   t['selected'] = true;
    // }
    // for (var i in injections) {
    //   i['selected'] = true;
    // }
    _updateTime();

    // Initialize medicine state
    for (var med in medicines) {
      med['doctorDays'] = (med['days'] ?? 1);
      med['currentDays'] = med['days'] ?? 1;
    }
  }

  // List<Map<String, dynamic>> getAllPrescriptionMedicines() {
  //   final prescriptions = consultation ?? [];
  //
  //   List<Map<String, dynamic>> allMedicines = [];
  //
  //   for (var p in consultation) {
  //     final meds = p['medicines'] ?? [];
  //     for (var m in meds) {
  //       allMedicines.add(m);
  //     }
  //   }
  //   return allMedicines;
  // }

  List<Map<String, dynamic>> getAllPrescriptionMedicines() {
    final meds = consultation['medicines'];

    if (meds is List) {
      return meds
          .map<Map<String, dynamic>>((m) => Map<String, dynamic>.from(m))
          .toList();
    }

    return [];
  }

  double calculateMedicineTotal(List meds) {
    double total = 0;

    for (var med in meds) {
      final dispenses = med['dispenses'] ?? [];
      for (var d in dispenses) {
        total += (d['amount'] ?? 0).toDouble();
      }
    }
    return total;
  }

  String? _dateTime;
  void _updateTime() {
    setState(() {
      _dateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
    });
  }

  // double get totalCharges =>
  //     _listTotal(medicines) + _listTotal(injections) + _listTotal(tonics);

  // double get totalCharges {
  //   return calculateMedicineTotal(getAllPrescriptionMedicines());
  // }
  double get totalCharges {
    return _listTotal(medicines);
  }

  double _listTotal(List items) {
    print('items $items');
    double sum = 0;
    if (widget.index == 1) {
      for (var item in items) {
        if (item['selected'] == true) {
          final val = item['total_amount'] - item['total'] ?? 0;
          sum += val is int ? val.toDouble() : val;
        }
      }
    } else {
      for (var item in items) {
        if (item['selected'] == true) {
          final val = item['total'] ?? 0;
          sum += val is int ? val.toDouble() : val;
        }
      }
    }
    return sum;
  }
  // ==================== STOCK UTILS ====================

  List<Map<String, dynamic>> buildStockItems({
    required List<Map<String, dynamic>> medicines,
    // required List<Map<String, dynamic>> injections,
    // required List<Map<String, dynamic>> tonics,
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

    return stockItems;
  }

  Future<void> updateStockAfterPayment({
    required List<Map<String, dynamic>> medicines,
  }) async {
    for (var med in medicines) {
      if (med['selected'] != true) continue;
      final stock = ((med['Medician']['stock'] ?? 0) as num).toInt();
      final used = ((med['quantityNeeded'] ?? 0) as num).toInt();
      final newStock = stock - used;

      await MedicineService().updateMedicineStock(med['Medician']['id'], {
        "stock": newStock,
      });
    }
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
        'medicineQueue': injection == true ? 'ONGOING' : 'COMPLETED',
        //'medicineTonic': false,
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
    } catch (e) {
      throw Exception("Failed updating medication status");
    }
  }

  // Future<void> _updateDispenseQuantity() async {
  //   try {
  //     final service = PrescriptionService();
  //     for (var med in medicines) {
  //       if (med['selected'] != true) continue;
  //
  //       final dispenses = med['dispenses'] as List?;
  //       if (dispenses == null || dispenses.isEmpty) continue;
  //
  //       // Assuming we update the first dispense record associated with this medicine for this prescription
  //       final dispenseId = dispenses[0]['id'];
  //       final int quantity = (med['quantityNeeded'] as num).toInt();
  //       final double amount = (med['total'] as num).toDouble();
  //       final String batchNo = dispenses[0]['batch_Id'].toString();
  //
  //       await service.updatePrescriptionDispenseQuantity(
  //         id: dispenseId,
  //         dispensedQuantity: quantity,
  //         days: med['currentDays'],
  //         amount: amount,
  //         batchId: batchNo,
  //       );
  //     }
  //   } catch (e) {
  //     debugPrint("Error updating dispense quantity: $e");
  //     // Optional: rethrow or handle specific errors if needed
  //   }
  // }

  Future<void> _updateDispenseQuantity() async {
    try {
      print('work1');
      final service = PrescriptionService();

      for (var med in medicines) {
        print('work2');
        if (med['selected'] != true) continue;

        final dispenses = med['dispenses'] as List?;
        if (dispenses == null || dispenses.isEmpty) continue;
        print('work3');
        final int dispenseId = (dispenses[0]['id'] as num).toInt();
        final int quantity = (med['quantityNeeded'] as num).toInt();
        print('work4');
        final double amount = (med['total'] as num).toDouble();
        print('work5');
        final int days = (med['currentDays'] as num).toInt(); // 🔥 FIX HERE
        final String batchNo = dispenses[0]['batch_Id'].toString();
        print('work6');
        await service.updatePrescriptionDispenseQuantity(
          id: dispenseId,
          dispensedQuantity: quantity,
          days: days, // now int
          amount: amount,
          batchId: batchNo,
        );
      }
    } catch (e) {
      debugPrint("Error updating dispense quantity: $e");
    }
  }

  // Future<void> updatePrescriptionCreateMedicineAdministration() async {
  //   print('updateAndCreateMedicineAdministration this work');
  //   try {
  //     final service = PrescriptionService();
  //     print('work1');
  //
  //     // Determine if any medicine quantity was decreased
  //     bool hasDecreasedQuantity = false;
  //     for (var med in medicines) {
  //       if (med['selected'] == true) {
  //         final doctorDays = (med['doctorDays'] as num?)?.toDouble() ?? 0;
  //         final currentDays = (med['currentDays'] as num?)?.toDouble() ?? 0;
  //         final dispenses = med['dispenses'] as List?;
  //         if (dispenses == null || dispenses.isEmpty) continue;
  //         print('work3');
  //         final int dispenseId = (dispenses[0]['id'] as num).toInt();
  //         final int quantity = (med['quantityNeeded'] as num).toInt();
  //         print('work4');
  //         final double amount = (med['total'] as num).toDouble();
  //         print('work5');
  //         final int days = (med['currentDays'] as num).toInt(); // 🔥 FIX HERE
  //         final String batchNo = dispenses[0]['batch_Id'].toString();
  //         final String mediStatus = med['status'];
  //         print('work6');
  //
  //         if (currentDays < doctorDays) {
  //           hasDecreasedQuantity = true;
  //           break;
  //         }
  //       }
  //     }
  //     print('work2');
  //
  //     // Set status based on whether any medicine quantity was decreased
  //     final String status = hasDecreasedQuantity
  //         ? 'PARTIALLY_DISPENSED'
  //         : 'DISPENSED';
  //
  //     await service.updatePrescriptionCreateMedicineAdministration(
  //       prescriptionId: consultation['Prescription'][0]['id'],
  //       hospitalId: consultation['hospital_Id'],
  //       patientId: consultation['patient_Id'],
  //       status: status,
  //       dispenseId: dispenseId,
  //       dispensedQuantity: quantity,
  //       days: days, // now int
  //       amount: amount,
  //       batchId: batchNo,
  //       mediStatus: mediStatus,
  //       patientType: consultation['patientType'],
  //     );
  //     print('work3');
  //   } catch (e) {
  //     debugPrint('Error: $e');
  //   }
  // }

  Future<void> updatePrescriptionCreateMedicineAdministration() async {
    try {
      final service = PrescriptionService();

      bool hasPartial = false;
      print('work1');
      // 1️⃣ First pass → determine overall prescription status
      for (var med in medicines) {
        if (med['selected'] != true) continue;

        final doctorDays = (med['doctorDays'] as num?)?.toDouble() ?? 0;
        final currentDays = (med['currentDays'] as num?)?.toDouble() ?? 0;

        if (currentDays < doctorDays) {
          hasPartial = true;
          break;
        }
      }
      print('work2');
      final String status = hasPartial ? 'PARTIALLY_DISPENSED' : 'DISPENSED';

      // 2️⃣ Second pass → update each selected medicine
      for (var med in medicines) {
        if (med['selected'] != true) continue;

        final dispenses = med['dispenses'] as List?;
        if (dispenses == null || dispenses.isEmpty) continue;

        final int dispenseId = (dispenses[0]['id'] as num).toInt();

        final int quantity = (med['quantityNeeded'] as num?)?.toInt() ?? 0;

        final double amount = (med['total'] as num?)?.toDouble() ?? 0.0;

        final int days = (med['currentDays'] as num?)?.toInt() ?? 0;

        final String batchNo = dispenses[0]['batch_Id'].toString();

        final String mediStatus = med['status'] ?? 'COMPLETED';
        print(
          'all data $dispenseId $quantity $days $amount $batchNo $mediStatus',
        );
        print('work1');
        await service.updatePrescriptionCreateMedicineAdministration(
          prescriptionId: consultation['id'],
          hospitalId: consultation['hospital_Id'],
          patientId: consultation['patient_Id'],
          status: status,
          dispenseId: dispenseId,
          dispensedQuantity: quantity,
          days: days,
          amount: amount,
          batchId: batchNo,
          mediStatus: mediStatus,
          patientType: consultation['consultation']['patientType'],
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  // ==================== PAYMENT DIALOG ====================

  void showPrintDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Print",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedValue =
            Curves.easeInOutBack.transform(animation.value) - 1.0;

        return Transform.scale(
          scale: animation.value,
          child: Opacity(
            opacity: animation.value,
            child: Dialog(
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Gradient Icon Container
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade700],
                        ),
                      ),
                      child: const Icon(
                        Icons.print_rounded,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      "Print Bill",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      "The bill has been generated successfully.\nWould you like to print it now?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 28),

                    Row(
                      children: [
                        // Cancel Button
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context, true);
                            },
                            child: const Text(
                              "No",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        // Print Button
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 5,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.blue.shade600,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              final medicalBillSelectedMedicines =
                                  widget.index == 1
                                  ? medicines
                                        .where(
                                          (m) =>
                                              m['selected'] == true &&
                                              m['status'] != 'CANCELLED',
                                        )
                                        .map(
                                          (m) => {
                                            'name':
                                                m['medicine']?['name'] ??
                                                'Medicine',
                                            'quantityNeeded':
                                                m['quantityNeeded'] -
                                                m['dispensed_quantity'],
                                            'total':
                                                m['total_amount'] -
                                                m['dispenses'][0]['amount'],
                                            'batchNo':
                                                m['dispenses'][0]['batch_Id'],
                                            'days': m['days'],
                                            'after_Eat': m['after_Eat'],
                                            'morning': m['morning'],
                                            'afternoon': m['afternoon'],
                                            'night': m['night'],
                                            'category':
                                                m['medicine']['category'],
                                            'medicine': m['medicine'],
                                          },
                                        )
                                        .toList()
                                  : medicines
                                        .where(
                                          (m) =>
                                              m['selected'] == true &&
                                              m['status'] != 'CANCELLED',
                                        )
                                        .map(
                                          (m) => {
                                            'name':
                                                m['medicine']?['name'] ??
                                                'Medicine',
                                            'quantityNeeded':
                                                m['quantityNeeded'],
                                            'total': m['total'],
                                            'batchNo':
                                                m['dispenses'][0]['batch_Id'],
                                            'days': m['days'],
                                            'after_Eat': m['after_Eat'],
                                            'morning': m['morning'],
                                            'afternoon': m['afternoon'],
                                            'night': m['night'],
                                            'category':
                                                m['medicine']['category'],
                                            'medicine': m['medicine'],
                                          },
                                        )
                                        .toList();

                              MedicalPdfBillMaker.generateMedicalBillPdf(
                                patientData: widget.consultation['patient'],
                                allConsultation: widget.consultation,
                                totalAmount: totalCharges,
                                medicines: medicalBillSelectedMedicines,
                              );
                              // Your print logic here
                              print("Printing Bill...");
                            },
                            child: const Text(
                              "Yes, Print",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
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
          ),
        );
      },
    );
  }
  // ==================== PAYMENT HANDLER ====================

  void _showHandlePayment() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // final consultationId = consultation['id'];
      int? paymentId;

      // if (consultation['Prescription']?.isNotEmpty ?? false) {
      //   paymentId = consultation['Prescription'][0]['payment_Id'];
      // }

      if (consultation.isNotEmpty) {
        paymentId = consultation['payment_Id'];
      }

      if (paymentId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Payment ID not found')));
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

      // await PaymentService().updatePayment(paymentId, {'amount': totalCharges});
      await PaymentService().updatePayment(paymentId, {
        'status': 'PAID',
        'staff_Id': staffId.toString(),
        'paymentType': paymentMode,
        'updatedAt': _dateTime.toString(),
      });

      // 3️⃣ Update stock after payment
      // await updateStockAfterPayment(
      //   medicines: (medicines).cast<Map<String, dynamic>>(),
      // );
      await updatePrescriptionCreateMedicineAdministration(); //1
      _updateStatus(); //2
      setState(() => paymentSuccess = true);
      Navigator.pop(context, true);
      if (mounted) {
        showPrintDialog(context); //3

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful!'),
            backgroundColor: Colors.green,
          ),
        );
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

  bool get hasSelectedItems {
    return medicines.any((m) => m['selected'] == true);
  }

  @override
  Widget build(BuildContext context) {
    print('consultation ${widget.consultation}');
    print('medicine $medicines');
    // final Prescription = consultation['Prescription'];

    final patient = consultation['patient'] ?? {};
    final doctor = consultation['consultation']['Doctor'] ?? {};
    // final drAllocatedDays =
    //     (consultation['MedicinePatient'] != null &&
    //         consultation['MedicinePatient'].isNotEmpty)
    //     ? consultation['MedicinePatient'][0]['days'] ?? 1
    //     : 1;

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
                  //_buildMedicineTable(drAllocatedDays),
                  _buildMedicineTable(),
                  const SizedBox(height: 18),

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

  Widget _buildMedicineTable() {
    if (medicines.isEmpty) return const SizedBox();

    return _buildTableCard(
      title: "Medicines",
      icon: Icons.medical_services,
      columns: const [
        "Select",
        "Medicine",
        "Days",
        "Qty",
        "AC/PC",
        "Sessions",
        "Unit Price",
        "Total",
      ],
      rows: medicines.map<List<dynamic>>((med) {
        final name = med['medicine']?['name'] ?? 'Medicine';
        print('medi $med');

        // Use normalized values that are updated by _updateDays
        final int totalQty = (med['quantityNeeded'] as num?)?.toInt() ?? 0;
        final double totalAmount = (med['total'] as num?)?.toDouble() ?? 0;
        // final double unitPrice =
        //     med['medicine']['batches'][0]['selling_price_unit'];

        final int batchId = med['dispenses'][0]['batch_Id'];

        final batch = med['medicine']['batches'].firstWhere(
          (b) => b['id'] == batchId,
        );

        final double unitPrice = (batch['selling_price_unit'] as num)
            .toDouble();

        String getDosePattern(Map<String, dynamic> med) {
          final int morning = med['morning'] == true ? 1 : 0;
          final int afternoon = med['afternoon'] == true ? 1 : 0;
          final int night = med['night'] == true ? 1 : 0;

          return '$morning - $afternoon - $night';
        }

        String getEatType(Map<String, dynamic> med) {
          final bool? afterEat = med['after_food'];

          if (afterEat == null) return '';
          return afterEat ? 'PC' : 'AC';
        }

        final String dosePattern = getDosePattern(med); // e.g. 1-0-1
        final String eatType = getEatType(med); // AC / PC

        return [
          _selectToggleButton(med),
          name,
          _buildDaysCell(med),
          totalQty,
          eatType,
          dosePattern,
          "₹ ${unitPrice.toStringAsFixed(1)}",
          "₹ ${totalAmount.toStringAsFixed(1)}",
        ];
      }).toList(),
    );
  }

  // Widget _buildDaysCell(Map<String, dynamic> med) {
  //   final category =
  //       med['medicine']?['category']?.toString().toLowerCase() ?? '';
  //
  //   if (category.toLowerCase() != 'tablets') {
  //     return Center(
  //       child: Text(
  //         '${med['currentDays'] ?? med['days'] ?? 0}',
  //         style: const TextStyle(fontWeight: FontWeight.bold),
  //       ),
  //     );
  //   }
  //
  //   return _dayControls(med);
  // }
  Widget _buildDaysCell(Map<String, dynamic> med) {
    final category =
        med['medicine']?['category']?.toString().toLowerCase() ?? '';

    if (category != 'tablets') {
      final days = med['days'];

      return Center(
        child: Text(
          (days == null || days == 0) ? '-' : days.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }

    return _dayControls(med);
  }

  // List<Map<String, dynamic>> _normalizeMedicines(List list) {
  //   return list.map<Map<String, dynamic>>((m) {
  //     int days = m['days'] ?? 1;
  //
  //     int sessionCount = 0;
  //     if (m['morning'] == true) sessionCount++;
  //     if (m['afternoon'] == true) sessionCount++;
  //     if (m['night'] == true) sessionCount++;
  //
  //     //final qtyPerTime = double.tryParse(m['quantity']?.toString() ?? '0') ?? 0;
  //     final qtyPerTime = (m['dosage'] as num?)?.toDouble() ?? 0;
  //
  //     final qtyPerDay = qtyPerTime * sessionCount;
  //     final totalQty = (qtyPerDay * days).ceil();
  //
  //     final price =
  //         double.tryParse(m['Medician']?['amount']?.toString() ?? '0') ?? 0;
  //
  //     return {
  //       ...m,
  //       'selected': true,
  //       'doctorDays': days,
  //       'currentDays': days,
  //       'allowedMax': days,
  //       'quantityNeeded': totalQty,
  //       'total': totalQty * price,
  //     };
  //   }).toList();
  // }

  List<Map<String, dynamic>> _normalizeMedicines(List list) {
    return list.map<Map<String, dynamic>>((m) {
      double days = double.parse(m['days'].toString()) ?? 1.0;

      int sessionCount = 0;
      if (m['morning'] == true) sessionCount++;
      if (m['afternoon'] == true) sessionCount++;
      if (m['night'] == true) sessionCount++;

      double qtyPerTimes = 1.0;
      final rawDosage = m['dosage']?.toString() ?? '1';
      // Try parsing directly first
      if (double.tryParse(rawDosage) != null) {
        qtyPerTimes = double.parse(rawDosage);
      } else {
        // Extract first number if present
        final match = RegExp(r"([0-9]*\.?[0-9]+)").firstMatch(rawDosage);
        if (match != null) {
          qtyPerTimes = double.tryParse(match.group(0)!) ?? 1.0;
        }
      }

      // final qtyPerDay = qtyPerTimes * sessionCount;
      // final totalQty = (qtyPerDay * days).ceil();
      final String category = (m['medicine']?['category'] ?? '')
          .toString()
          .toLowerCase();

      int totalQty;

      if (category == 'tablets') {
        // Tablets → calculated
        final double qtyPerDay = qtyPerTimes * sessionCount;
        totalQty = (qtyPerDay * days).ceil();
      } else {
        // Other categories → direct quantity
        totalQty = (m['total_quantity'] as num?)?.toInt() ?? 0;
      }

      final price = (m['dispenses'] != null && m['dispenses'].isNotEmpty)
          ? (totalQty > 0
                ? (m['dispenses'][0]['amount'] as num).toDouble() / totalQty
                : 0.0)
          : (m['medicine'] != null &&
                m['medicine']['batches'] != null &&
                m['medicine']['batches'].isNotEmpty)
          ? (m['medicine']['batches'][0]['selling_price_unit'] as num)
                .toDouble()
          : (m['Medician']?['amount'] as num?)?.toDouble() ?? 0;

      return {
        ...m,
        'selected': true,
        'doctorDays': days,
        'currentDays': days,
        'allowedMax': days,
        'quantityNeeded': totalQty,
        'total': totalQty * price,
        'unitPrice': price,
      };
    }).toList();
  }

  void _updateDays(Map<String, dynamic> med, double newDays) {
    final maxDays = med['allowedMax'];
    if (newDays < 1 || newDays > maxDays) return;

    // Update the values first
    med['currentDays'] = newDays;

    int sessionCount = 0;
    if (med['morning'] == true) sessionCount++;
    if (med['afternoon'] == true) sessionCount++;
    if (med['night'] == true) sessionCount++;

    double qtyPerTimes = 1.0;
    final rawDosage = med['dosage']?.toString() ?? '1';
    if (double.tryParse(rawDosage) != null) {
      qtyPerTimes = double.parse(rawDosage);
    } else {
      final match = RegExp(r"([0-9]*\.?[0-9]+)").firstMatch(rawDosage);
      if (match != null) {
        qtyPerTimes = double.tryParse(match.group(0)!) ?? 1.0;
      }
    }

    final qtyPerDay = qtyPerTimes * sessionCount;
    final totalQty = (qtyPerDay * newDays).ceil();

    // Use stored unitPrice
    final unitPrice = (med['unitPrice'] as num?)?.toDouble() ?? 0.0;

    med['quantityNeeded'] = totalQty;
    med['total'] = totalQty * unitPrice;

    // Force rebuild by creating a new list reference
    setState(() {
      medicines = List.from(medicines);
    });
  }

  Widget _dayControls(Map<String, dynamic> med) {
    // Use state-managed currentDays and allowedMax
    final double currentDays = (med['currentDays'] as num?)?.toDouble() ?? 1;
    final double maxDays = (med['allowedMax'] as num?)?.toDouble() ?? 1;

    bool canDec = currentDays > 1;
    bool canInc = currentDays < maxDays;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle, color: Colors.red),
          onPressed: canDec ? () => _updateDays(med, currentDays - 1) : null,
        ),
        Text(
          currentDays.toInt().toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: Icon(
            Icons.add_circle,
            color: canInc ? Colors.green : Colors.grey,
          ),
          onPressed: canInc ? () => _updateDays(med, currentDays + 1) : null,
        ),
      ],
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
    print('selectedMedicines $medicines');
    final selectedMedicines = medicines
        .where((m) => m['selected'] == true && m['status'] != 'CANCELLED')
        .map(
          (m) => {
            'name': m['medicine']?['name'] ?? 'Medicine',
            'quantityNeeded': m['quantityNeeded'] - m['dispensed_quantity'],
            'total': m['total_amount'] - m['dispenses'][0]['amount'],
          },
        )
        .toList();

    final medicalBillSelectedMedicines = widget.index == 1
        ? medicines
              .where((m) => m['selected'] == true && m['status'] != 'CANCELLED')
              .map(
                (m) => {
                  'name': m['medicine']?['name'] ?? 'Medicine',
                  'quantityNeeded':
                      m['quantityNeeded'] - m['dispensed_quantity'],
                  'total': m['total_amount'] - m['dispenses'][0]['amount'],
                  'batchNo': m['dispenses'][0]['batch_Id'],
                  'days': m['days'],
                  'after_Eat': m['after_Eat'],
                  'morning': m['morning'],
                  'afternoon': m['afternoon'],
                  'night': m['night'],
                  'category': m['medicine']['category'],
                  'medicine': m['medicine'],
                },
              )
              .toList()
        : medicines
              .where((m) => m['selected'] == true && m['status'] != 'CANCELLED')
              .map(
                (m) => {
                  'name': m['medicine']?['name'] ?? 'Medicine',
                  'quantityNeeded': m['quantityNeeded'],
                  'total': m['total'],
                  'batchNo': m['dispenses'][0]['batch_Id'],
                  'days': m['days'],
                  'after_Eat': m['after_Eat'],
                  'morning': m['morning'],
                  'afternoon': m['afternoon'],
                  'night': m['night'],
                  'category': m['medicine']['category'],
                  'medicine': m['medicine'],
                },
              )
              .toList();

    if (paymentSuccess || widget.index == 1) {
      // ✅ Prescription Bill layout shown after payment success

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
                  headers: ["Medicine", "Qty", "Amount"],
                  rows: selectedMedicines.map((m) {
                    return [
                      m['name'],
                      m['quantityNeeded'],
                      "₹ ${m['total'].toStringAsFixed(1)}",
                    ];
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
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Amount",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                  Text(
                    totalCharges.toStringAsFixed(1),
                    // "₹ ${totalCharges.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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
                    IconButton(
                      onPressed: () =>
                          MedicalPdfBillMaker.generateMedicalBillPdf(
                            patientData: widget.consultation['patient'],
                            allConsultation: widget.consultation,
                            totalAmount: totalCharges,
                            medicines: medicalBillSelectedMedicines,
                          ),
                      icon: FaIcon(
                        FontAwesomeIcons.filePdf,
                        color: Colors.white,
                        size: 25,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const FaIcon(
                        FontAwesomeIcons.whatsapp,
                        color: Colors.white,
                        size: 26,
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
                    //Spacer(),
                    // ElevatedButton.icon(
                    //   icon: _isLoading
                    //       ? const SizedBox(
                    //           height: 18,
                    //           width: 18,
                    //           child: CircularProgressIndicator(
                    //             strokeWidth: 2.2,
                    //             color: Colors.white,
                    //           ),
                    //         )
                    //       : const Icon(Icons.check_circle, color: Colors.white),
                    //   label: Text(
                    //     _isLoading ? "Updating..." : "OK ",
                    //
                    //     style: const TextStyle(
                    //       color: Colors.white,
                    //       fontWeight: FontWeight.w600,
                    //     ),
                    //   ),
                    //   style: ElevatedButton.styleFrom(
                    //     backgroundColor: primaryColor,
                    //     padding: const EdgeInsets.symmetric(
                    //       horizontal: 18,
                    //       vertical: 12,
                    //     ),
                    //     shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.circular(10),
                    //     ),
                    //   ),
                    //   onPressed: _isLoading ? null : _updateStatus,
                    // ),
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
            _info("Medicines Total", "₹ ${totalCharges.toStringAsFixed(2)}"),

            const Divider(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Grand Total",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                ),
                Text(
                  "₹ ${totalCharges.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),
            Row(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton.icon(
                    onPressed: (_isLoading || !hasSelectedItems)
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
                      // backgroundColor: (_isLoading || totalCharges == 0)
                      //     ? Colors
                      //           .grey // disabled gray color
                      //     : primaryColor,
                      backgroundColor: (_isLoading || !hasSelectedItems)
                          ? Colors.grey
                          : Colors.blueAccent,

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
                Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.cancel, color: Colors.white),
                  label: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      for (var m in medicines) {
                        m['selected'] = false;
                      }
                    });
                  },
                ),
              ],
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
}
