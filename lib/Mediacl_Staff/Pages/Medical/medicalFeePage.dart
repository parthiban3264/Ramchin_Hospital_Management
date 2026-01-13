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

  List<Map<String, dynamic>> getAllPrescriptionMedicines() {
    final prescriptions = consultation['Prescription'] ?? [];

    List<Map<String, dynamic>> allMedicines = [];

    for (var p in prescriptions) {
      final meds = p['medicines'] ?? [];
      for (var m in meds) {
        allMedicines.add(m);
      }
    }
    return allMedicines;
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
    double sum = 0;
    for (var item in items) {
      if (item['selected'] == true) {
        final val = item['total'] ?? 0;
        sum += val is int ? val.toDouble() : val;
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
    } catch (e) {
      throw Exception("Failed updating medication status");
    }
  }

  // ==================== PAYMENT HANDLER ====================

  void _showHandlePayment() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // final consultationId = consultation['id'];
      int? paymentId;

      if (consultation['Prescription']?.isNotEmpty ?? false) {
        paymentId = consultation['Prescription'][0]['payment_Id'];
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

      await PaymentService().updatePayment(paymentId, {'amount': totalCharges});
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

      if (mounted) {
        setState(() => paymentSuccess = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful!'),
            backgroundColor: Colors.green,
          ),
        );
        //await updateMedicationStatus();
      }
    } catch (e) {
      print('Payment failed: $e');
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
    final Prescription = consultation['Prescription'];
    print('Prescription $Prescription');
    final patient = consultation['Patient'] ?? {};
    final doctor = consultation['Doctor'] ?? {};
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

  //----------------------medicine table--------------------
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
        "Unit Price",
        "Total",
      ],
      rows: medicines.map((med) {
        print('med $med');
        final name = med['medicine']?['name'] ?? 'Medicine';
        // final dispenses = med['dispenses'] ?? [];
        // int totalQty = 0;
        // double totalAmt = 0;
        // final price = (med['Medician']?['amount'] as num?)?.toDouble() ?? 0;
        // for (var d in dispenses) {
        //   totalQty += (d['dispensed_quantity'] ?? 0) as int;
        //   totalAmt += (d['amount'] ?? 0).toDouble();
        // }
        //
        // final unitPrice = totalQty == 0 ? 0 : totalAmt / totalQty;

        // final int totalQty = med['total_quantity'] ?? 0;
        // final double totalAmt = (med['dispenses'][0]['amount'] ?? 0).toDouble();
        //
        // final double unitPrice = totalQty == 0 ? 0 : totalAmt / totalQty;

        final int totalQty = med['quantityNeeded'] ?? 0;
        final double totalAmt = (med['total'] ?? 0).toDouble();
        final double unitPrice = totalQty == 0 ? 0 : totalAmt / totalQty;

        return [
          _selectToggleButton(med),
          name,
          // _dayControls(med),
          _buildDaysCell(med),
          totalQty,
          "₹ ${unitPrice.toStringAsFixed(1)}",
          "₹ ${totalAmt.toStringAsFixed(1)}",
        ];
      }).toList(),
    );
  }

  Widget _buildDaysCell(Map<String, dynamic> med) {
    final category =
        med['medicine']?['category']?.toString().toLowerCase() ?? '';

    if (category != 'tablet') {
      return const Text('-', style: TextStyle(fontWeight: FontWeight.bold));
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
      int days = m['days'] ?? 1;

      int sessionCount = 0;
      if (m['morning'] == true) sessionCount++;
      if (m['afternoon'] == true) sessionCount++;
      if (m['night'] == true) sessionCount++;

      final qtyPerTime = (m['dosage']).toString() ?? 0;
      final qtyPerTimes = double.parse(qtyPerTime.toString());

      final qtyPerDay = qtyPerTimes * sessionCount;
      final totalQty = (qtyPerDay * days).ceil();

      final price = (m['dispenses'] != null && m['dispenses'].isNotEmpty)
          ? (m['dispenses'][0]['amount'] as num).toDouble() / totalQty
          : (m['Medician']?['amount'] as num?)?.toDouble() ?? 0;

      return {
        ...m,
        'selected': true,
        'doctorDays': days,
        'currentDays': days,
        'allowedMax': days,
        'quantityNeeded': totalQty,
        'total': totalQty * price,
      };
    }).toList();
  }

  // void _updateDays(Map<String, dynamic> med, int newDays) {
  //   final maxDays = med['allowedMax'];
  //   if (newDays < 1 || newDays > maxDays) return;
  //
  //   setState(() {
  //     med['currentDays'] = newDays;
  //
  //     int sessionCount = 0;
  //     if (med['morning'] == true) sessionCount++;
  //     if (med['afternoon'] == true) sessionCount++;
  //     if (med['night'] == true) sessionCount++;
  //
  //     // final qtyPerTime =
  //     //     double.tryParse(med['quantity']?.toString() ?? '0') ?? 0;
  //     final qtyPerTime = (med['dosage'] as num?)?.toDouble() ?? 0;
  //
  //     final qtyPerDay = qtyPerTime * sessionCount;
  //     final totalQty = (qtyPerDay * newDays).ceil();
  //
  //     final price =
  //         double.tryParse(med['Medician']?['amount']?.toString() ?? '0') ?? 0;
  //
  //     med['quantityNeeded'] = totalQty;
  //     med['total'] = totalQty * price;
  //   });
  // }

  void _updateDays(Map<String, dynamic> med, int newDays) {
    final maxDays = med['allowedMax'];
    if (newDays < 1 || newDays > maxDays) return;

    setState(() {
      med['currentDays'] = newDays;

      int sessionCount = 0;
      if (med['morning'] == true) sessionCount++;
      if (med['afternoon'] == true) sessionCount++;
      if (med['night'] == true) sessionCount++;

      // final qtyPerTime = (med['dosage'] as num?)?.toDouble() ?? 0;
      //
      // final qtyPerDay = qtyPerTime * sessionCount;
      final qtyPerTime = (med['dosage']).toString() ?? 0;
      final qtyPerTimes = double.parse(qtyPerTime.toString());

      final qtyPerDay = qtyPerTimes * sessionCount;
      final totalQty = (qtyPerDay * newDays).ceil();

      final unitPrice = totalQty == 0
          ? 0
          : (med['total'] / med['quantityNeeded']);

      med['quantityNeeded'] = totalQty;
      med['total'] = totalQty * unitPrice;
    });
  }

  Widget _dayControls(Map<String, dynamic> med) {
    int currentDays = med['currentDays'];
    int maxDays = med['allowedMax'];

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
          currentDays.toString(),
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
    final allMeds = getAllPrescriptionMedicines();
    //final medicineTotal = calculateMedicineTotal(allMeds);
    final patientName = patient['name'] ?? '';
    final phoneNumber = patient['phone']?['mobile'] ?? '';
    // final selectedMedicines = medicines
    //     .where((m) => m['selected'] == true && m['status'] != 'CANCELLED')
    //     .toList();
    final selectedMedicines = medicines
        .where((m) => m['selected'] == true && m['status'] != 'CANCELLED')
        .map(
          (m) => {
            'name': m['medicine']?['name'] ?? 'Medicine',
            'quantityNeeded': m['quantityNeeded'],
            'total': m['total'],
          },
        )
        .toList();

    // for (var m in medicines) {}
    //
    // final selectedTonics = tonics
    //     .where((t) => t['selected'] == true && t['status'] != 'CANCELLED')
    //     .toList();
    // final selectedInjections = injections
    //     .where((i) => i['selected'] == true && i['status'] != 'CANCELLED')
    //     .toList();

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
                // _buildSimpleTable(
                //   headers: ["Medicine", "Qty", "Amount"],
                //   rows: allMeds.map((m) {
                //     final name = m['medicine']?['name'] ?? 'Medicine';
                //
                //     int qty = 0;
                //     double amt = 0;
                //
                //     for (var d in (m['dispenses'] ?? [])) {
                //       qty += (d['dispensed_quantity'] ?? 0) as int;
                //       amt += (d['amount'] ?? 0).toDouble();
                //     }
                //
                //     return [
                //       name,
                //       qty.toString(),
                //       "₹ ${amt.toStringAsFixed(2)}",
                //     ];
                //   }).toList(),
                // ),
                _buildSimpleTable(
                  headers: ["Medicine", "Qty", "Amount"],
                  rows: selectedMedicines.map((m) {
                    return [
                      m['name'],
                      m['quantityNeeded'],
                      "₹ ${m['total'].toStringAsFixed(2)}",
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
                        // tonics: selectedTonics,
                        // injections: selectedInjections,
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
            _info("Medicines Total", "₹ ${totalCharges.toStringAsFixed(2)}"),

            // if (medicines.isNotEmpty) ...[
            //   _info(
            //     "Medicines Total",
            //     "₹ ${_listTotal(medicines).toStringAsFixed(1)}",
            //   ),
            // ],
            // if (tonics.isNotEmpty) ...[
            //   _info(
            //     "Tonics Total",
            //     "₹ ${_listTotal(tonics).toStringAsFixed(1)}",
            //   ),
            // ],
            // if (injections.isNotEmpty) ...[
            //   _info(
            //     "Injections Total",
            //     "₹ ${_listTotal(injections).toStringAsFixed(1)}",
            //   ),
            // ],
            const Divider(height: 15),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     const Text(
            //       "Grand Total",
            //       style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            //     ),
            //     Text(
            //       "₹ ${medicineTotal.toStringAsFixed(2)}",
            //       style: const TextStyle(
            //         fontWeight: FontWeight.bold,
            //         fontSize: 16,
            //         color: Colors.green,
            //       ),
            //     ),
            //   ],
            // ),
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
                    // onPressed: (_isLoading || totalCharges == 0)
                    //     ? null
                    //     : _showHandlePayment,
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
