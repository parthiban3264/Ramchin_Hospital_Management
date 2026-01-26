import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Pages/NotificationsPage.dart';
import '../../../../Pages/payment_modal.dart';
import '../../../../Services/charge_Service.dart';
import '../../../../Services/consultation_service.dart';
import '../../../../Services/payment_service.dart';
import '../../../../Services/socket_service.dart';
import '../../../../Services/testing&scanning_service.dart';
import '../../Medical/Widget/whatsApp_Send_PaymentBill.dart';
import 'widget.dart';

class FeesPaymentPage extends StatefulWidget {
  final Map<String, dynamic> fee;
  final Map<String, dynamic> patient;
  final int index;
  final String page;

  const FeesPaymentPage({
    super.key,
    required this.fee,
    required this.patient,
    required this.index,
    required this.page,
  });

  @override
  State<FeesPaymentPage> createState() => FeesPaymentPageState();
}

class FeesPaymentPageState extends State<FeesPaymentPage> {
  final prefs = SharedPreferences.getInstance();
  bool _isProcessing = false;
  final socketService = SocketService();
  String? logo;
  String? hospitalName;
  String? hospitalPlace;
  bool _isLoading = false;
  bool _isBuildingPdf = false;

  late TextEditingController cellController;
  late TextEditingController nameController;
  late TextEditingController addressController;
  late TextEditingController dobController;
  late TextEditingController feeController;
  late TextEditingController idController;
  late TextEditingController referredDoctorController;

  @override
  void initState() {
    super.initState();
    _updateTime();
    cellController = TextEditingController(
      text: extractString(widget.patient['phone'], 'mobile'),
    );
    nameController = TextEditingController(
      text: extractName(widget.patient['name']),
    );
    idController = TextEditingController(
      text: extractName(widget.patient['id']),
    );
    addressController = TextEditingController(
      text: extractString(widget.patient['address'], 'Address'),
    );
    referredDoctorController = TextEditingController(
      text: extractString(
        widget.fee['Consultation']?['referredByDoctorName'] ?? '',
      ),
    );
    dobController = TextEditingController(
      text: formatDob(extractString(widget.patient['dob'])),
    );
    feeController = TextEditingController(
      text: widget.fee['amount']?.toString() ?? '',
    );
    _loadHospitalLogo();
  }

  String? _dateTime;
  void _updateTime() {
    setState(() {
      _dateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
    });
  }

  void _loadHospitalLogo() async {
    final prefs = await SharedPreferences.getInstance();

    logo = prefs.getString('hospitalPhoto');
    hospitalName = prefs.getString('hospitalName');
    hospitalPlace = prefs.getString('hospitalPlace');
    setState(() {});
  }

  String formatDob(String? dob) {
    if (dob == null || dob.trim().isEmpty) return 'N/A';

    try {
      // Try parsing "dd-MM-yyyy" format first
      DateTime date;
      if (dob.contains('-') && dob.split('-')[0].length == 2) {
        date = DateFormat('dd-MM-yyyy').parse(dob);
      } else {
        date = DateTime.parse(dob); // fallback for ISO format
      }

      return DateFormat('dd-MM-yyyy').format(date);
    } catch (e) {
      return dob;
    }
  }

  static String calculateAge(String? dob) {
    if (dob == null || dob.trim().isEmpty) return 'N/A';

    try {
      DateTime birthDate;
      if (dob.contains('-') && dob.split('-')[0].length == 2) {
        // parse "02-11-2004"
        birthDate = DateFormat('dd-MM-yyyy').parse(dob);
      } else {
        // parse ISO "2004-11-02"
        birthDate = DateTime.parse(dob);
      }

      final now = DateTime.now();
      int age = now.year - birthDate.year;

      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }

      if (age < 0) age = 0;
      return '$age';
    } catch (e) {
      return 'N/A';
    }
  }

  static String getFormattedDate(dynamic value) {
    if (value == null) return "-";

    try {
      DateTime date;

      // If already DateTime
      if (value is DateTime) {
        date = value;
      }
      // If string → fix formats like "2025-12-03 03:07 PM"
      else if (value is String) {
        // Try normal parse
        try {
          date = DateTime.parse(value);
        } catch (_) {
          // Try manual parse for AM/PM formats
          date = DateFormat("yyyy-MM-dd hh:mm a").parse(value);
        }
      } else {
        return "-";
      }

      return DateFormat("dd-MM-yyyy hh:mm a").format(date);
    } catch (e) {
      return value.toString();
    }
  }

  Future<void> _showBillConfirmationDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isPrinting = false;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: const Text(
                "Payment Successfully",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: const Text("Do you want to print the bill now?"),
              actions: [
                /// ❌ NO → refresh
                TextButton(
                  onPressed: isPrinting
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          Navigator.pop(context, true); // ✅ refresh
                        },
                  child: const Text("No"),
                ),

                /// ✅ YES → print or cancel → refresh ALWAYS refresh ALWAYS
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  onPressed: isPrinting
                      ? null
                      : () async {
                          setDialogState(() => isPrinting = true);
                          Navigator.pop(ctx);

                          setState(() => _isBuildingPdf = true);

                          try {
                            final pdf = await buildPdf(
                              cellController: cellController,
                              dobController: dobController,
                              addressController: addressController,
                              fee: widget.fee,
                              hospitalName: hospitalName!,
                              hospitalPlace: hospitalPlace!,
                              nameController: nameController,
                              logo: logo!,
                            );

                            if (mounted) {
                              setState(() => _isBuildingPdf = false);
                            }

                            // 🔑 user may print OR cancel – we don't care
                            await Printing.layoutPdf(
                              onLayout: (format) async => pdf.save(),
                            );
                          } catch (e) {
                            debugPrint("Print error: $e");
                          } finally {
                            if (mounted) {
                              // 🔥 ALWAYS refresh parent
                              Navigator.pop(context, true);
                            }
                          }
                        },
                  child: isPrinting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Yes, Print",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handlePayment() async {
    final amount = widget.fee['amount']?.toDouble() ?? 0.0;
    final paymentId = widget.fee['id'];
    final type = widget.fee['type'].toString().toUpperCase();

    final paymentResult = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PaymentModal(registrationFee: amount),
    );

    if (paymentResult == null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment cancelled')));
      return;
    }
    final String paymentMode = paymentResult?['paymentMode'] ?? 'unknown';
    final prefs = await SharedPreferences.getInstance();

    // ✅ Payment succeeded → update backend
    setState(() => _isProcessing = true);
    final staffId = prefs.getString('userId');

    // if (widget.fee['type'] == 'ADMISSIONFEE') {
    //   isDischarged = widget.fee['Admission']?['status'] == 'DISCHARGED';
    // }
    bool isDischarged = widget.fee['Admission']?['status'] == 'DISCHARGED';
    final response = await PaymentService().updatePayment(paymentId, {
      'status': (widget.fee['type'] != 'ADMISSIONFEE')
          ? 'PAID'
          : isDischarged == false
          ? 'PARTIALLY_PAID'
          : 'PAID',
      // 'transactionId': paymentResult['transactionId'],
      "staff_Id": staffId.toString(),
      "paymentType": paymentMode,
      "updatedAt": _dateTime.toString(),
    });
    // if (widget.fee['type'] == 'ADVANCEFEE' ||
    //     widget.fee['type'] == 'DAILYTREATMENTFEE') {
    //   //final admissionId = widget.fee['Admission']['id'];
    //   final List<int> chargesIds = widget.fee['Admission']['charges']
    //       .map<int>((c) => c['id'])
    //       .toList();
    //   print('chargesIds $chargesIds');
    //   await ChargeService().updateChargesByAdmission(
    //     chargesIds: chargesIds,
    //     status: 'PAID',
    //   );
    // }
    if (widget.fee['type'] == 'ADVANCEFEE') {
      final int admissionId = widget.fee['Admission']['id'];

      final List<int> chargesIds = (widget.fee['Admission']['charges'] as List)
          .cast<Map<String, dynamic>>()
          .where(
            (charge) =>
                charge['description'] == 'Inpatient Advance Fee' &&
                charge['admissionId'] == admissionId,
          )
          .map((charge) => charge['id'] as int)
          .toList();

      print('chargesIds $chargesIds');

      await ChargeService().updateChargesByAdmission(
        chargesIds: chargesIds,
        status: 'PAID',
      );
    }
    if (widget.fee['type'] == 'DAILYTREATMENTFEE' ||
        widget.fee['type'] == 'DISCHARGEFEE') {
      final int admissionId = widget.fee['Admission']['id'];

      final List<int> chargesIds = (widget.fee['Admission']['charges'] as List)
          .cast<Map<String, dynamic>>()
          .where((charge) => charge['admissionId'] == admissionId)
          .map((charge) => charge['id'] as int)
          .toList();

      print('chargesIds $chargesIds');

      await ChargeService().updateChargesByAdmission(
        chargesIds: chargesIds,
        status: 'PAID',
      );
    }

    // final Id = widget.patient['Consultation']?[0]?['id'];
    final consultationId = widget.fee['consultation_Id'];

    if (type == 'REGISTRATIONFEE') {
      await ConsultationService().updateConsultation(consultationId, {
        "paymentStatus": true,
      });
    } else if (type == 'TESTINGFEESANDSCANNINGFEE') {
      final testings = widget.fee['TestingAndScanningPatients'];

      final testId = (testings != null && testings.isNotEmpty)
          ? testings[0]['payment_Id']
          : null;

      await TestingScanningService().updateTestAndScan(testId);
      await ConsultationService().updateConsultation(consultationId, {
        "queueStatus": 'PENDING',
      });
    } else {}
    // else if (type == 'MEDICINEFEEANDINJECTIONFEE') {
    // await ConsultationService().updateConsultation(Id, {
    // "paymentStatus": true,
    // });
    // }

    setState(() => _isProcessing = false);

    if (response != null && response['status'] == 'success' && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Payment Successful')));
      //Navigator.pop(context, true);
      await _showBillConfirmationDialog();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Failed to update payment status.')),
        );
      }
    }
  }

  Future<void> _updateSugarTest() async {
    try {
      final consultationId = widget.fee['consultation_Id'];
      final paymentId = widget.fee['id'];

      final consultation = widget.fee['Consultation'];
      final num paymentAmount = widget.fee['amount'] ?? 0;
      final num sugarFee = consultation?['sugarTestFee'] ?? 0;

      // 🔒 Safety check
      if (sugarFee <= 0) {
        return;
      }

      final num finalTotal = (paymentAmount - sugarFee).clamp(
        0,
        double.infinity,
      );

      /// 🔹 Update Payment Amount
      await PaymentService().updatePayment(paymentId, {
        'amount': finalTotal,
        'updatedAt': _dateTime.toString(),
      });

      /// 🔹 Update Consultation (remove sugar test)
      await ConsultationService().updateConsultation(consultationId, {
        "sugerTest": false,
        "sugerTestQueue": false,
        "sugarTestFee": 0,
      });

      /// 🔹 Update local UI state
      setState(() {
        widget.fee['amount'] = finalTotal;
        consultation['sugarTestFee'] = 0;
      });
    } catch (e) {
      setState(() {});
    }
  }

  // Future<void> _updateTestAndScan() async {
  //   final testings = widget.fee['TestingAndScanningPatients'];
  //
  //   final paymentId = widget.fee['id'];
  //
  //   final num paymentAmount = widget.fee['amount'] ?? 0;
  //   final num testFee = testings?['amount'] ?? 0;
  //
  //   // 🔒 Safety check
  //   if (testFee <= 0) {
  //     print('No test fee to remove');
  //     return;
  //   }
  //
  //   final num finalTotal = (paymentAmount - testFee).clamp(0, double.infinity);
  //
  //   /// 🔹 Update Payment Amount
  //   await PaymentService().updatePayment(paymentId, {
  //     'amount': finalTotal,
  //     'updatedAt': _dateTime.toString(),
  //   });
  //
  //   final testId = (testings != null && testings.isNotEmpty)
  //       ? testings[0]['payment_Id']
  //       : null;
  //   try {
  //     await ConsultationService().updateConsultation(testId, {
  //       "unSelectedOptions": '',
  //     });
  //   } catch (e) {
  //     print(e);
  //   }
  // }
  bool isValid(String? value) {
    return value != null &&
        value.trim() != 'null' &&
        value.trim().isNotEmpty &&
        value.trim() != '0' &&
        value.trim() != 'N/A' &&
        value.trim() != '-' &&
        value.trim() != '_' &&
        value.trim() != '-mg/dL';
  }

  bool hasAnyVital({
    String? temperature,
    String? bloodPressure,
    String? sugar,
    String? height,
    String? weight,
    String? BMI,
    String? PK,
    String? SpO2,
  }) {
    return isValid(temperature) ||
        isValid(bloodPressure) ||
        isValid(sugar) ||
        isValid(height) ||
        isValid(weight) ||
        isValid(BMI) ||
        isValid(PK) ||
        isValid(SpO2);
  }

  bool _isValid(String? value) {
    return value != null &&
        value.trim() != 'null' &&
        value.trim().isNotEmpty &&
        value.trim() != '0' &&
        value.trim() != 'N/A' &&
        value.trim() != '-' &&
        value.trim() != '_' &&
        value.trim() != '-mg/dL';
  }

  Future<bool> _confirmRemove(String title) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text("Confirm Remove"),
            content: Text("Remove $title from bill?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Remove"),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _normalize(String s) {
    if (s == 'ROOM RENT') return 'Room Rent';
    if (s == 'DOCTOR FEE') return 'Doctor Fee';
    if (s == 'NURSE FEE') return 'Nurse Fee';
    return s;
  }

  @override
  Widget build(BuildContext context) {
    print('widget.: ${widget.fee}');
    final List tests = widget.fee["TestingAndScanningPatients"] ?? [];
    final consultation = widget.fee['Consultation'] ?? {};
    // final temperature = consultation['temperature'] ?? '';
    final bloodPressure = consultation['bp'] ?? {} ?? '_';
    final sugar = consultation['sugar'] ?? '_';
    final height = consultation['height'].toString() ?? '_';
    final weight = consultation['weight'].toString() ?? '_';
    final BMI = consultation['BMI'].toString() ?? '_';
    final PK = consultation['PK'].toString() ?? '_';
    final SpO2 = consultation['SPO2'].toString() ?? '_';
    // final bool isTestOnly = consultation['isTestOnly'] ?? false;
    // final referredDoctorName =
    //     consultation['referredByDoctorName'].toString() ?? '-';

    final num? registrationFee = consultation?['registrationFee'];
    // final num? consultationFee =
    //     consultation?['consultationFee'] + registrationFee ?? '0';
    final num consultationFee =
        (consultation?['consultationFee'] ?? 0) + (registrationFee ?? 0);

    final num? emergencyFee = consultation?['emergencyFee'];
    final num? sugarTestFee = consultation?['sugarTestFee'];
    final tokenNo =
        (consultation['tokenNo'] == null || consultation['tokenNo'] == 0)
        ? '-'
        : consultation['tokenNo'].toString();
    // final num totalAmount =
    //     (registrationFee ?? 0) +
    //     (consultationFee ?? 0) +
    //     (emergencyFee ?? 0) +
    //     (sugarTestFee ?? 0);

    final Color themeColor = const Color(0xFFBF955E);
    const Color background = Color(0xFFF8F8F8);
    // bool hasSubAmounts(dynamic selectedOption) {
    //   if (selectedOption is Map) {
    //     return selectedOption.values.any((v) => v != null && v != 0);
    //   }
    //
    //   if (selectedOption is List) {
    //     return selectedOption.any(
    //       (e) => e is Map && e['amount'] != null && e['amount'] != 0,
    //     );
    //   }
    //
    //   return false;
    // }
    final admission = widget.fee['Admission'];
    final bed = admission?['bed'];
    final ward = bed?['ward'];

    final String? roomName = ward?['name'];
    final num roomRent = num.tryParse(ward?['rent']?.toString() ?? '0') ?? 0;

    List<MapEntry<String, num>> parseSelectedOption(dynamic selectedOption) {
      if (selectedOption is Map) {
        return selectedOption.entries
            .map(
              (e) => MapEntry(
                e.key.toString(),
                num.tryParse(e.value.toString()) ?? 0,
              ),
            )
            .where((e) => e.value > 0)
            .toList();
      }

      if (selectedOption is List) {
        return selectedOption
            .whereType<Map>()
            .map(
              (e) => MapEntry(
                e['name']?.toString() ?? '',
                num.tryParse(e['amount']?.toString() ?? '') ?? 0,
              ),
            )
            .where((e) => e.key.isNotEmpty && e.value > 0)
            .toList();
      }

      return [];
    }

    Future<void> _removeOption({
      required int testIndex,
      required String optionKey,
      required num optionAmount,
    }) async {
      final tests = widget.fee['TestingAndScanningPatients'];
      final test = tests[testIndex];
      final Map options = Map.from(test['selectedOptionAmounts'] ?? {});

      if (options.length <= 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("At least one option must remain")),
        );
        return;
      }

      final confirm = await _confirmRemove(optionKey);
      if (!confirm) return;

      try {
        // 🔹 Remove option from backend test
        options.remove(optionKey);
        await TestingScanningService().updateTesting(test['id'], {
          "selectedOptionAmounts": options,
          "selectedOptions": options.keys.toList(),
          "amount": (test['amount'] ?? 0) - optionAmount,
        });

        // 🔹 Update payment
        final num updatedTotal = (widget.fee['amount'] - optionAmount).clamp(
          0,
          double.infinity,
        );
        await PaymentService().updatePayment(widget.fee['id'], {
          'amount': updatedTotal,
          'updatedAt': DateTime.now().toString(),
        });

        // 🔹 Update UI
        test['selectedOptionAmounts'] = options;
        test['amount'] = (test['amount'] ?? 0) - optionAmount;
        setState(() {
          widget.fee['amount'] = updatedTotal;
        });
      } catch (e) {
        debugPrint("Error deleting option: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to remove option")),
        );
      }
    }

    Future<void> _removeTestAt(int index) async {
      final List tests = widget.fee['TestingAndScanningPatients'] ?? [];

      if (tests.length <= 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("At least one test/scan must remain")),
        );
        return;
      }

      final test = tests[index];
      final num testAmount = test['amount'] ?? 0;
      if (testAmount <= 0) return;

      final confirm = await _confirmRemove(test['title'] ?? 'Test');
      if (!confirm) return;

      try {
        // 🔹 Delete from backend
        await TestingScanningService().deleteTesting(test['id']);

        // 🔹 Update payment
        final num updatedTotal = (widget.fee['amount'] - testAmount).clamp(
          0,
          double.infinity,
        );
        await PaymentService().updatePayment(widget.fee['id'], {
          'amount': updatedTotal,
          'updatedAt': DateTime.now().toString(),
        });

        // 🔹 Update UI locally
        tests.removeAt(index);
        setState(() {
          widget.fee['amount'] = updatedTotal;
          widget.fee['TestingAndScanningPatients'] = tests;
        });
      } catch (e) {
        debugPrint("Error deleting test: $e");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to remove test")));
      }
    }

    void editAmountDialog(
      BuildContext context,
      num currentAmount,
      Function(num) onSave,
    ) {
      final controller = TextEditingController(text: currentAmount.toString());

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          bool isLoading = false;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  "Edit Amount",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: "Amount",
                        prefixText: "₹ ",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                actionsPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                actions: [
                  TextButton(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: isLoading
                        ? null
                        : () async {
                            final paymentId = widget.fee['id'];
                            final int admissionId =
                                widget.fee['Admission']['id'];

                            final List<int> chargesIds =
                                (widget.fee['Admission']['charges'] as List)
                                    .cast<Map<String, dynamic>>()
                                    .where(
                                      (charge) =>
                                          charge['description'] ==
                                              'Inpatient Advance Fee' &&
                                          charge['admissionId'] == admissionId,
                                    )
                                    .map((charge) => charge['id'] as int)
                                    .toList();
                            final value = num.tryParse(controller.text);

                            if (value == null) return;

                            setDialogState(() => isLoading = true);

                            try {
                              await PaymentService().updatePayment(paymentId, {
                                'amount': value,
                                'updatedAt': _dateTime.toString(),
                              });
                              await ChargeService()
                                  .updateAdvanceChargesByAdmission(
                                    chargesIds: chargesIds,
                                    amount: value,
                                  );

                              onSave(value);
                              Navigator.pop(context);
                            } catch (e) {
                              setDialogState(() => isLoading = false);
                            }
                          },
                    child: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text("Update"),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    //// ===================== Daily charges cal..---------------------
    final charges = (admission?['charges'] ?? [])
        .where(
          (c) =>
              (c['status'] ?? '').toString().toUpperCase() ==
              (widget.index == 1 ? 'PAID' : 'PENDING'),
        )
        .toList();
    charges.sort((a, b) {
      DateTime parse(dynamic c) {
        final dateStr = c['chargeDate'] ?? c['createdAt'];
        return DateTime.tryParse(dateStr?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
      }

      return parse(a).compareTo(parse(b));
    });

    String formatDate(DateTime d) =>
        "${d.day.toString().padLeft(2, '0')} "
        "${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]} "
        "${d.year}";

    Widget dateHeader(List charges) {
      if (charges.isEmpty) return const SizedBox.shrink();

      final dates = charges
          .map((c) => DateTime.parse(c['chargeDate']))
          .toList();

      final from = dates.first;
      final to = dates.last;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          from.day == to.day
              ? formatDate(from)
              : "${formatDate(from)} → ${formatDate(to)}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
      );
    }

    // Map<String, List<Map<String, dynamic>>> groupedCharges = {};
    //
    // for (final c in charges) {
    //   final key = c['description'] ?? 'Charge';
    //   groupedCharges.putIfAbsent(key, () => []).add(c);
    // }

    const knownCharges = {'ROOM RENT', 'DOCTOR FEE', 'NURSE FEE'};

    Map<String, List<Map<String, dynamic>>> grouped = {
      'Room Rent': [],
      'Doctor Fee': [],
      'Nurse Fee': [],
      'Others': [],
    };

    // for (final c in charges) {
    //   final desc = (c['description'] ?? '').toString().toUpperCase();
    //
    //   if (knownCharges.contains(desc)) {
    //     grouped[_normalize(desc)]!.add(c);
    //   } else {
    //     if (desc == 'INPATIENT ADVANCE FEE') {
    //       continue;
    //     }
    //     grouped['Others']!.add(c);
    //   }
    // }
    for (final c in charges) {
      final desc = (c['description'] ?? '').toString().toUpperCase();

      // ⛔ Always skip advance fee
      if (desc == 'INPATIENT ADVANCE FEE') {
        continue;
      }

      if (knownCharges.contains(desc)) {
        grouped[_normalize(desc)]!.add(c);
      } else {
        grouped['Others']!.add(c);
      }
    }
    final num advanceAmount = (admission?['charges'] ?? [])
        .where(
          (c) =>
              (c['status'] ?? '').toString().toUpperCase() == 'PAID' &&
              (c['description'] ?? '').toString().toUpperCase() ==
                  'INPATIENT ADVANCE FEE' &&
              c['admissionId'] == widget.fee['Admission']['id'],
        )
        .fold<num>(
          0,
          (num sum, dynamic c) =>
              sum + (num.tryParse(c['amount']?.toString() ?? '0') ?? 0),
        );
    final num chargePendingAmount = (admission?['charges'] ?? [])
        .where(
          (c) =>
              (c['status'] ?? '').toString().toUpperCase() == 'PENDING' &&
              c['admissionId'] == widget.fee['Admission']['id'],
        )
        .fold<num>(
          0,
          (num sum, dynamic c) =>
              sum + (num.tryParse(c['amount']?.toString() ?? '0') ?? 0),
        );

    final num chargePaidAmount = (admission?['charges'] ?? [])
        .where(
          (c) =>
              (c['status'] ?? '').toString().toUpperCase() == 'PAID' &&
              (c['description'] ?? '').toString().toUpperCase() !=
                  'INPATIENT ADVANCE FEE' &&
              c['admissionId'] == widget.fee['Admission']['id'],
        )
        .fold<num>(
          0,
          (num sum, dynamic c) =>
              sum + (num.tryParse(c['amount']?.toString() ?? '0') ?? 0),
        );
    final total = widget.index != 1
        ? calculateTotal(widget.fee['amount']) -
              (widget.fee['received_Amount'] ?? 0)
        : calculateTotal(widget.fee['amount']);

    final bool isDischarge = widget.fee['type'] == 'DISCHARGEFEE';
    final num safeAdvance = advanceAmount ?? 0;

    final num diff = widget.index != 1
        ? chargePendingAmount - safeAdvance
        : chargePaidAmount - safeAdvance;

    final String label = isDischarge && diff < 0
        ? 'Return ${widget.index == 1 ? '' : 'Amount'}'
        : 'Total';

    final num displayAmount = isDischarge ? diff.abs() : total;

    return Scaffold(
      backgroundColor: background,

      appBar: widget.page == 'reg'
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(100),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
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
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          "Fees Payment",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.notifications,
                            color: Colors.white,
                          ),
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
                            Navigator.popUntil(
                              context,
                              (route) => count++ >= 2,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🧾 Bill Header
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          "INVOICE / HOSPITAL BILL",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Date: ${DateTime.now().toString().split(' ').first}",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Text(
                        //   "Token No: ${widget.fee['Consultation']['tokenNo'] ?? '-'}",
                        //   style: TextStyle(
                        //     fontSize: 13,
                        //     color: Colors.grey[700],
                        //   ),
                        // ),
                        Row(
                          mainAxisSize: MainAxisSize
                              .min, // row takes minimal horizontal space
                          children: [
                            Text(
                              'Token No: ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              tokenNo,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const Divider(thickness: 1.2, height: 25),
                      ],
                    ),
                  ),

                  // 👤 Patient Information
                  const Text(
                    "Patient Details",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _infoRow("Name ", nameController.text),
                  _infoRow("PID ", idController.text),
                  _infoRow("Cell No ", cellController.text),
                  _infoRow("DOB ", dobController.text),
                  _infoRow("AGE ", calculateAge(dobController.text)),
                  _infoRow("Address ", addressController.text),

                  const Divider(thickness: 1.2, height: 30),
                  if (widget.fee['type'] == 'DAILYTREATMENTFEE' ||
                      widget.fee['type'] == 'DISCHARGEFEE' ||
                      widget.fee['type'] == 'ADVANCEFEE') ...[
                    const Text(
                      "Admission Details",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      "Admit Id ",
                      widget.fee['Admission']['id'].toString(),
                    ),
                    _infoRow(
                      "Ward Name",
                      '${widget.fee['Admission']['bed']['ward']['name']} - '
                          '${widget.fee['Admission']['bed']['ward']['type']}',
                    ),
                    _infoRow(
                      "Ward No ",
                      widget.fee['Admission']['bed']['ward']['id'].toString(),
                    ),
                    _infoRow(
                      "Bed No ",
                      widget.fee['Admission']['bed']['bedNo'].toString(),
                    ),

                    _infoRow(
                      "Admit Date ",
                      widget.fee['Admission']['admitTime']
                          .toString()
                          .split('T')
                          .first,
                    ),
                    if (widget.fee['type'] == 'DISCHARGEFEE')
                      _infoRow(
                        "Discharge Date ",
                        widget.fee['Admission']['dischargeTime']
                            .toString()
                            .split('T')
                            .first,
                      ),

                    //_infoRow("Dr Name ", ['name']),
                    const Divider(thickness: 1.2, height: 30),
                  ],

                  // 💳 Fee Details
                  // if (widget.fee['type'] == 'REGISTRATIONFEE') ...[
                  //   Center(
                  //     child: const Text(
                  //       "Vitals",
                  //       style: TextStyle(
                  //         fontWeight: FontWeight.w600,
                  //         fontSize: 16,
                  //         color: Colors.black87,
                  //       ),
                  //     ),
                  //   ),
                  //   const Divider(thickness: 1.2, height: 30),
                  //
                  //   if (widget.fee['type'] == 'REGISTRATIONFEE')
                  //     if (hasAnyVital(
                  //       temperature: temperature,
                  //       bloodPressure: bloodPressure,
                  //       sugar: sugar,
                  //       height: height,
                  //       weight: weight,
                  //       BMI: BMI,
                  //       PK: PK,
                  //       SpO2: SpO2,
                  //     ))
                  //       _buildVitalsDetails(
                  //         temperature: temperature,
                  //         bloodPressure: bloodPressure,
                  //         sugar: sugar,
                  //         height: height,
                  //         weight: weight,
                  //         BMI: BMI,
                  //         PK: PK,
                  //         SpO2: SpO2,
                  //       ),
                  //
                  //   const Divider(thickness: 1.2, height: 30),
                  // ],

                  // 💳 Fee Details
                  Center(
                    child: const Text(
                      "Fee Summary",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const Divider(thickness: 1.5, height: 20),
                  const SizedBox(height: 2),
                  if (widget.fee['type'] == 'REGISTRATIONFEE') ...[
                    // Row(
                    //   children: [
                    //     Text(
                    //       "${widget.fee['reason']}",
                    //       style: const TextStyle(
                    //         fontSize: 16,
                    //         fontWeight: FontWeight.bold,
                    //       ),
                    //     ),
                    //     Spacer(),
                    //     Text(
                    //       "₹ ${feeController.text}",
                    //       textAlign: TextAlign.end,
                    //       style: const TextStyle(
                    //         fontSize: 15,
                    //         color: Colors.black87,
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    Column(
                      children: [
                        // feeRowWithRemove(
                        //   title: "Registration Fee",
                        //   amount: registrationFee,
                        //   removable: false, // ❌ disabled
                        // ),
                        feeRowWithRemove(
                          title: "Consultation Fee",
                          amount: consultationFee,
                          removable: false, // ❌ disabled
                        ),

                        feeRowWithRemove(
                          title: "Emergency Fee",
                          amount: emergencyFee,
                          removable: false, // ❌ disabled
                        ),

                        feeRowWithRemove(
                          title: "Sugar Test Fee",
                          amount: sugarTestFee,
                          removable: true, // ✅ enabled
                          onRemove: () {
                            _updateSugarTest();
                            setState(() {
                              consultation['sugarTestFee'] = 0;
                            });
                          },
                        ),
                      ],
                    ),

                    // _billRow(
                    //   "${widget.fee['reason']}",
                    //   "₹ ${feeController.text}",
                    // ),
                  ],
                  if (widget.fee['type'] == 'ADMISSIONFEE') ...[
                    // 🔹 Header only
                    feeHeader("Room & Bed charges"),
                    if (widget.index != 1) ...[
                      if (widget.fee['received_Amount'] != null &&
                          widget.fee['received_Amount'] != 0) ...[
                        const SizedBox(height: 5),
                        feeHeaderWithAmount(
                          "Received Amount",
                          widget.fee['received_Amount'],
                        ),
                      ],
                    ],

                    // 🔹 Room
                    if (ward?['name'] != null)
                      feeRowWithRemove(
                        title:
                            "${ward['type']} - ${ward['name']}( ${widget.fee['Admission']['bed']['bedNo']} )",
                        amount:
                            num.tryParse(ward?['rent']?.toString() ?? '0') ?? 0,
                        removable: false,
                      ),

                    // 🔹 Charges
                    // for (final charge in admission?['charges'] ?? [])
                    //   feeRowWithRemove(
                    //     title: charge['description'] ?? 'Charge',
                    //     amount:
                    //         num.tryParse(charge['amount']?.toString() ?? '0') ??
                    //         0,
                    //     removable: false,
                    //   ),
                    // 🔹 Charges (only PENDING)
                    // if (widget.index != 1)
                    //   {
                    //     for (final charge in admission?['charges'] ?? [])
                    //       if ((charge['status'] ?? '')
                    //               .toString()
                    //               .toUpperCase() ==
                    //           'PENDING')
                    //         feeRowWithRemove(
                    //           title: charge['description'] ?? 'Charge',
                    //           amount:
                    //               num.tryParse(
                    //                 charge['amount']?.toString() ?? '0',
                    //               ) ??
                    //               0,
                    //           removable: false,
                    //         ),
                    //   }
                    // else
                    //   {
                    //     for (final charge in admission?['charges'] ?? [])
                    //       feeRowWithRemove(
                    //         title: charge['description'] ?? 'Charge',
                    //         amount:
                    //             num.tryParse(
                    //               charge['amount']?.toString() ?? '0',
                    //             ) ??
                    //             0,
                    //         removable: false,
                    //       ),
                    //   },
                    if (widget.index == 1)
                      for (final charge in admission?['charges'] ?? [])
                        if ((charge['status'] ?? '').toString().toUpperCase() ==
                            'PAID')
                          feeRowWithRemove(
                            title: charge['description'] ?? 'Charge',
                            amount:
                                num.tryParse(
                                  charge['amount']?.toString() ?? '0',
                                ) ??
                                0,
                            removable: false,
                          ),
                    if (widget.index != 1)
                      for (final charge in admission?['charges'] ?? [])
                        if ((charge['status'] ?? '').toString().toUpperCase() ==
                            'PENDING')
                          feeRowWithRemove(
                            title: charge['description'] ?? 'Charge',
                            amount:
                                num.tryParse(
                                  charge['amount']?.toString() ?? '0',
                                ) ??
                                0,
                            removable: false,
                          ),
                  ],

                  // if (widget.fee['type'] == 'ADVANCEFEE') ...[
                  //   feeRowWithRemove(
                  //     title: "Inpatient Advance",
                  //     amount: widget.fee['amount'],
                  //     removable: false, // ❌ disabled
                  //   ),
                  // ],
                  if (widget.fee['type'] == 'ADVANCEFEE') ...[
                    feeRowWithRemove(
                      title: "Inpatient Advance",
                      amount: widget.fee['amount'],
                      removable: false,
                      onEdit: () => editAmountDialog(
                        context,
                        widget.fee['amount'],
                        (newAmount) {
                          setState(() {
                            widget.fee['amount'] = newAmount;
                          });
                        },
                      ),
                    ),
                  ],

                  if (widget.fee['type'] == 'DAILYTREATMENTFEE' ||
                      widget.fee['type'] == 'DISCHARGEFEE') ...[
                    // if (widget.index == 1)
                    //   for (final charge in admission?['charges'] ?? [])
                    //     if ((charge['status'] ?? '').toString().toUpperCase() ==
                    //         'PAID')
                    //       feeRowWithRemove(
                    //         title: charge['description'] ?? 'Charge',
                    //         amount:
                    //             num.tryParse(
                    //               charge['amount']?.toString() ?? '0',
                    //             ) ??
                    //             0,
                    //         removable: false,
                    //       ),
                    // if (widget.index != 1)
                    //   for (final charge in admission?['charges'] ?? [])
                    //     if ((charge['status'] ?? '').toString().toUpperCase() ==
                    //         'PENDING')
                    //       feeRowWithRemove(
                    //         title: charge['description'] ?? 'Charge',
                    //         amount:
                    //             num.tryParse(
                    //               charge['amount']?.toString() ?? '0',
                    //             ) ??
                    //             0,
                    //         removable: false,
                    //       ),
                    // Column(
                    //   crossAxisAlignment: CrossAxisAlignment.center,
                    //   children: [
                    //     // 📅 Date range header
                    //     dateHeader(charges),
                    //
                    //     const SizedBox(height: 4),
                    //
                    //     // 💰 Grouped charges
                    //     for (final entry in groupedCharges.entries)
                    //       _buildGroupedFee(entry.key, entry.value),
                    //   ],
                    // ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        dateHeader(charges),

                        for (final entry in grouped.entries)
                          if (entry.value.isNotEmpty)
                            _groupedFeeRow(entry.key, entry.value),
                      ],
                    ),
                  ],

                  if (tests.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      "${widget.fee['reason']}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ...tests.map((t) {
                    //   final title = t["title"]?.toString() ?? "-";
                    //   final amount = t["amount"]?.toString() ?? "0";
                    //   final Map<String, dynamic> selectedOption =
                    //       Map<String, dynamic>.from(t['selectedOption'] ?? {});
                    //
                    //   return _billRow(title, selectedOption, "₹ $amount");
                    // }).toList(),
                    // ...tests.expand((t) {
                    //   final title = t["title"]?.toString() ?? "-";
                    //   final amount = t["amount"]?.toString() ?? "0";
                    //   final selectedOption = t['selectedOptionAmounts'];
                    //
                    //   final bool showSubRows = hasSubAmounts(selectedOption);
                    //   final entries = showSubRows
                    //       ? parseSelectedOption(selectedOption)
                    //       : <MapEntry<String, num>>[];
                    //
                    //   return [
                    //     // ✅ ALWAYS show parent row
                    //     // _billRow(title, amount, isBold: true, fontSize: 16),
                    //     _billRowWithRemove(
                    //       label: title,
                    //       value: amount,
                    //       onRemove: () => _removeTestAt(index),
                    //     ),
                    //
                    //     // ✅ Show sub rows ONLY for new data
                    //     if (showSubRows)
                    //       ...entries.map(
                    //         (e) => _subBillRow(e.key, e.value.toString()),
                    //       ),
                    //
                    //     const SizedBox(height: 8),
                    //   ];
                    // }),
                    // ...tests.asMap().entries.expand((entry) {
                    //   final index = entry.key;
                    //   final t = entry.value;
                    //
                    //   final title = t["title"]?.toString() ?? "-";
                    //   final amount = t["amount"]?.toString() ?? "0";
                    //   final selectedOption = t['selectedOptionAmounts'];
                    //   bool isLastItem = tests.length == 1;
                    //
                    //   final bool showSubRows = hasSubAmounts(selectedOption);
                    //   final entries = showSubRows
                    //       ? parseSelectedOption(selectedOption)
                    //       : <MapEntry<String, num>>[];
                    //
                    //   return [
                    //     // ✅ Parent row with remove
                    //     _billRowWithRemove(
                    //       label: title,
                    //       value: amount,
                    //       onRemove: () => _removeTestAt(index),
                    //     ),
                    //
                    //     // ✅ Sub rows (unchanged)
                    //     if (showSubRows)
                    //       ...entries.map(
                    //         (e) => _subBillRow(e.key, e.value.toString()),
                    //       ),
                    //
                    //     const SizedBox(height: 8),
                    //   ];
                    // }),
                    // ...tests.asMap().entries.expand((entry) {
                    //   final testIndex = entry.key;
                    //   final test = entry.value;
                    //
                    //   final title = test["title"]?.toString() ?? "-";
                    //   final testAmount = test["amount"]?.toDouble() ?? 0;
                    //   final selectedOption = test['selectedOptionAmounts'];
                    //
                    //   final entries = parseSelectedOption(selectedOption);
                    //
                    //   // 🔒 Check if last test or last option
                    //   final bool isLastTest = tests.length == 1;
                    //
                    //   return [
                    //     /// ✅ Parent test row
                    //     _billRowWithRemove(
                    //       label: title,
                    //       value: testAmount.toStringAsFixed(0),
                    //       isDisabled: isLastTest,
                    //       onRemove: () => _removeTestAt(testIndex),
                    //     ),
                    //
                    //     /// ✅ Sub-option rows
                    //     if (entries.isNotEmpty)
                    //       ...entries.asMap().entries.map((optEntry) {
                    //         final optionIndex = optEntry.key;
                    //         final option = optEntry.value;
                    //
                    //         // 🔒 Disable icon if it's the last option in this test
                    //         final bool isLastOption = entries.length == 1;
                    //
                    //         return _subBillRowWithRemove(
                    //           label: option.key,
                    //           amount: option.value,
                    //           isDisabled: isLastOption,
                    //           onRemove: () {
                    //             _removeOption(
                    //               testIndex: testIndex,
                    //               optionKey: option.key,
                    //               optionAmount: option.value,
                    //             );
                    //           },
                    //         );
                    //       }),
                    //
                    //     const SizedBox(height: 8),
                    //   ];
                    // }),
                    ...tests.asMap().entries.expand((entry) {
                      final testIndex = entry.key;
                      final test = entry.value;

                      final title = test["title"]?.toString() ?? "-";
                      final testAmount = test["amount"]?.toDouble() ?? 0;
                      final selectedOption = test['selectedOptionAmounts'];
                      final entries = parseSelectedOption(selectedOption);

                      final bool isLastTest = tests.length == 1;

                      return [
                        // Parent test row
                        _billRowWithRemove(
                          label: title,
                          value: testAmount.toStringAsFixed(0),
                          isDisabled: isLastTest,
                          onRemove: () => _removeTestAt(testIndex),
                        ),

                        // Sub-options
                        if (entries.isNotEmpty)
                          ...entries.asMap().entries.map((optEntry) {
                            final option = optEntry.value;
                            final bool isLastOption = entries.length == 1;

                            return _subBillRowWithRemove(
                              label: option.key,
                              amount: option.value,
                              isDisabled: isLastOption,
                              onRemove: () {
                                _removeOption(
                                  testIndex: testIndex,
                                  optionKey: option.key,
                                  optionAmount: option.value,
                                );
                              },
                            );
                          }),

                        const SizedBox(height: 6),
                      ];
                    }),
                  ],

                  if (widget.fee['type'] == 'DISCHARGEFEE')
                    Column(
                      children: [
                        if (advanceAmount > 0) ...[
                          const Divider(thickness: 1.5, height: 6),
                          feeRowAdvance(
                            title: 'Inpatient Advance',
                            amount: advanceAmount,
                          ),
                        ],
                      ],
                    ),

                  const Divider(thickness: 1.5, height: 22),
                  // 🧮 Total Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (widget.index == 1) ...[
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 6),
                        Text('PAID', style: TextStyle(color: Colors.black)),

                        Spacer(),
                      ],

                      // Align(
                      //   alignment: Alignment.centerRight,
                      //   child: Text(
                      //     "Total : ₹ $total",
                      //     style: const TextStyle(
                      //       fontSize: 22,
                      //       fontWeight: FontWeight.bold,
                      //       color: Colors.black87,
                      //     ),
                      //   ),
                      // ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "$label : ₹ $displayAmount",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: widget.index == 1
                                ? (label == 'Return '
                                      ? Colors.blue
                                      : Colors.black87)
                                : (label == 'Return Amount'
                                      ? Colors.blue
                                      : Colors.black87),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // 💰 Pay Button
                  widget.index == 0
                      ? Row(
                          children: [
                            Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: _isProcessing ? 140 : 120,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: label == 'Return Amount'
                                        ? Colors.blue
                                        : Colors.green,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 14,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.receipt_long,
                                    color: Colors.white,
                                  ),
                                  label: _isProcessing
                                      ? const Text(
                                          "Processing...",
                                          style: TextStyle(color: Colors.white),
                                        )
                                      : Text(
                                          label == 'Return Amount'
                                              ? "Get Bill"
                                              : "Pay Bill",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                  onPressed: _isProcessing
                                      ? null
                                      : _handlePayment,
                                ),
                              ),
                            ),

                            if (widget.fee['type'] != 'DISCHARGEFEE') ...[
                              Spacer(),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  final paymentId = widget.fee['id'];
                                  final consultationId =
                                      widget.fee['type'] == 'ADMISSIONFEE' ||
                                          widget.fee['type'] ==
                                              'DAILYTREATMENTFEE'
                                      ? widget.fee['Admission']['id']
                                      : widget.fee['consultation_Id'];
                                  final staffId = prefs.getString('userId');
                                  if (context.mounted) {
                                    _showCancelDialog(
                                      context,
                                      paymentId: paymentId,
                                      consultationId: consultationId,
                                      staffId: staffId,
                                    );
                                  }
                                },
                                icon: Icon(
                                  widget.fee['type'] == 'DAILYTREATMENTFEE'
                                      ? Icons.skip_next
                                      : Icons.cancel,
                                  size: 22,
                                ),
                                label: Text(
                                  widget.fee['type'] == 'DAILYTREATMENTFEE'
                                      ? "Pay Later "
                                      : "Cancel ",
                                  style: TextStyle(fontSize: 18),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      widget.fee['type'] == 'DAILYTREATMENTFEE'
                                      ? Colors.blueAccent
                                      : Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // 🔹 Print Button
                            ElevatedButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                      setState(() {
                                        _isLoading = true;
                                        _isBuildingPdf = true;
                                      });

                                      try {
                                        final pdf = await buildPdf(
                                          cellController: cellController,
                                          dobController: dobController,
                                          addressController: addressController,
                                          fee: widget.fee,
                                          hospitalName: hospitalName!,
                                          hospitalPlace: hospitalPlace!,
                                          nameController: nameController,
                                          logo: logo!,
                                        );

                                        await Printing.layoutPdf(
                                          onLayout: (format) async =>
                                              pdf.save(),
                                        );
                                      } finally {
                                        setState(() => _isLoading = false);
                                        setState(() => _isBuildingPdf = false);
                                      }
                                    },
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.print,
                                      color: Colors.white,
                                    ),
                              label: Text(
                                _isLoading ? "Printing..." : "Print",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent.shade400,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5,
                              ),
                            ),

                            InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () async {
                                if (widget.fee['type'] == 'REGISTRATIONFEE') {
                                  await WhatsAppSendPaymentBill.sendRegistrationBill(
                                    phoneNumber: cellController.text.replaceAll(
                                      '+',
                                      '',
                                    ),
                                    patientName: nameController.text,
                                    patientId: idController.text,
                                    tokenNo: tokenNo,
                                    age: calculateAge(dobController.text),
                                    address: addressController.text,
                                    registrationFee:
                                        widget
                                            .fee['Consultation']?['registrationFee'] ??
                                        0,
                                    consultationFee:
                                        widget
                                            .fee['Consultation']?['consultationFee'] ??
                                        0,
                                    emergencyFee:
                                        widget
                                            .fee['Consultation']?['emergencyFee'] ??
                                        0,
                                    sugarTestFee:
                                        widget
                                            .fee['Consultation']?['sugarTestFee'] ??
                                        0,
                                    // temperature: temperature,
                                    bloodPressure: bloodPressure,
                                    sugar: sugar,
                                    height: height,
                                    weight: weight,
                                    BMI: BMI,
                                    PK: PK,
                                    SpO2: SpO2,
                                  );
                                } else if (widget.fee['type'] ==
                                    'TESTINGFEESANDSCANNINGFEE') {
                                  final List tests =
                                      widget
                                          .fee['TestingAndScanningPatients'] ??
                                      [];

                                  if (tests.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "No testing data to send",
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  await WhatsAppSendPaymentBill.sendTestingBill(
                                    phoneNumber: cellController.text.replaceAll(
                                      '+',
                                      '',
                                    ),
                                    patientName: nameController.text,
                                    patientId: idController.text,
                                    tokenNo: tokenNo,
                                    fee: widget.fee,
                                    age: calculateAge(dobController.text),
                                    address: addressController.text,
                                    tests: List<Map<String, dynamic>>.from(
                                      tests,
                                    ),
                                  );
                                } else if (widget.fee['type'] == 'ADVANCEFEE') {
                                  await WhatsAppSendPaymentBill.sendAdvanceBill(
                                    phoneNumber: cellController.text.replaceAll(
                                      '+',
                                      '',
                                    ),
                                    patientName: nameController.text,
                                    patientId: idController.text,
                                    tokenNo: tokenNo,
                                    age: calculateAge(dobController.text),
                                    address: addressController.text,
                                    advancedFee: widget.fee['amount'] ?? 0,
                                  );
                                } else if (widget.fee['type'] ==
                                        'DISCHARGEFEE' ||
                                    widget.fee['type'] == 'DAILYTREATMENTFEE') {
                                  await WhatsAppSendPaymentBill.sendDischargeBill(
                                    phoneNumber: cellController.text.replaceAll(
                                      '+',
                                      '',
                                    ),
                                    patientName: nameController.text,
                                    patientId: idController.text,
                                    tokenNo: tokenNo,
                                    age: calculateAge(dobController.text),
                                    address: addressController.text,
                                    advancedFee: widget.fee['amount'] ?? 0,
                                    fee: widget.fee,
                                  );
                                }
                              },

                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const FaIcon(
                                  FontAwesomeIcons.whatsapp,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                            ),

                            // 🔹 Share Button
                            // ElevatedButton.icon(
                            //   onPressed: () async {
                            //     final pdf = await buildPdf(
                            //       cellController: cellController,
                            //       dobController: dobController,
                            //       fee: widget.fee,
                            //       hospitalName: hospitalName!,
                            //       hospitalPlace: hospitalPlace!,
                            //       nameController: nameController,
                            //       logo: logo!,
                            //     );
                            //     await Printing.sharePdf(
                            //       bytes: await pdf.save(),
                            //       filename: "hospital_bill.pdf",
                            //     );
                            //   },
                            //
                            //   icon: const Icon(
                            //     Icons.share,
                            //     color: Colors.white,
                            //   ),
                            //   label: const Text(
                            //     "Share",
                            //     style: TextStyle(
                            //       color: Colors.white,
                            //       fontSize: 16,
                            //     ),
                            //   ),
                            //   style: ElevatedButton.styleFrom(
                            //     backgroundColor: Colors.green,
                            //     padding: const EdgeInsets.symmetric(
                            //       horizontal: 12,
                            //       vertical: 12,
                            //     ),
                            //     shape: RoundedRectangleBorder(
                            //       borderRadius: BorderRadius.circular(12),
                            //     ),
                            //     elevation: 5,
                            //   ),
                            // ),
                          ],
                        ),
                ],
              ),
            ),
          ),

          // 🌀 Loading Overlay
          // if (_isProcessing)
          //   Container(
          //     color: Colors.black38,
          //     child: const Center(
          //       child: CircularProgressIndicator(color: Colors.white),
          //     ),
          //   ),
          // 🌀 Loading Overlay (Payment OR PDF building)
          if (_isProcessing || _isBuildingPdf)
            Container(
              color: Colors.black38,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVitalsDetails({
    String? temperature,
    String? bloodPressure,
    String? sugar,
    String? height,
    String? weight,
    String? BMI,
    String? PK,
    String? SpO2,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Header
        const SizedBox(height: 8),

        if (_isValid(temperature)) _vitalRow("Temperature", "$temperature °F"),

        if (_isValid(bloodPressure)) _vitalRow("BP", bloodPressure!),

        if (_isValid(sugar)) _vitalRow("Sugar", "$sugar mg/dL"),

        if (_isValid(weight)) _vitalRow("Weight", "$weight kg"),

        if (_isValid(height)) _vitalRow("Height", "$height cm"),

        if (_isValid(BMI)) _vitalRow("BMI", BMI!),

        if (_isValid(PK)) _vitalRow("PR", "$PK bpm"),

        if (_isValid(SpO2)) _vitalRow("SpO₂", "$SpO2 %"),
      ],
    );
  }

  Widget _vitalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label :",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildGroupedFee(String title, List<Map<String, dynamic>> items) {
  //   final days = items.length;
  //   final perDayAmount = num.tryParse(items.first['amount'].toString()) ?? 0;
  //
  //   final totalAmount = items.fold<num>(
  //     0,
  //     (sum, c) => sum + (num.tryParse(c['amount'].toString()) ?? 0),
  //   );
  //
  //   final displayTitle = days > 1 ? "$title × ${days}d" : title;
  //
  //   return feeRowWithRemove(
  //     title: displayTitle,
  //     amount: totalAmount,
  //     removable: false,
  //   );
  // }
  Widget _groupedFeeRow(String title, List<Map<String, dynamic>> items) {
    final total = items.fold<num>(
      0,
      (sum, c) => sum + (num.tryParse(c['amount'].toString()) ?? 0),
    );

    final days = items.length;

    final displayTitle = (title != 'Others' && days > 1)
        ? "$title × ${days}d"
        : title;

    return feeRowWithRemove(
      title: displayTitle,
      amount: total,
      removable: false,
    );
  }

  Widget feeHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget feeHeaderWithAmount(String title, num? amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            "₹ ${amount?.toStringAsFixed(0) ?? '0'}",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _billRowWithRemove({
    required String label,
    required String value,
    required VoidCallback onRemove,
    required bool isDisabled,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),

          Text("₹ $value", style: const TextStyle(fontSize: 15)),

          /// 🔴 Remove icon (always shown)
          if (widget.index == 0)
            IconButton(
              icon: Icon(
                Icons.remove_circle_outline,
                size: 22,
                color: isDisabled ? Colors.grey : Colors.redAccent,
              ),
              onPressed: isDisabled
                  ? null // 🔒 disabled only for last item
                  : onRemove,
              tooltip: isDisabled
                  ? "At least one test/scan must remain"
                  : "Remove",
            ),
        ],
      ),
    );
  }

  // Widget feeRowWithRemove({
  //   required String title,
  //   required num? amount,
  //   required bool removable,
  //   VoidCallback? onRemove,
  // }) {
  //   if (amount == null || amount == 0) return const SizedBox.shrink();
  //
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 0),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.center,
  //       children: [
  //         Expanded(child: feeRow(title, amount)),
  //
  //         /// Remove Icon
  //         if (widget.index != 1) ...[
  //           IconButton(
  //             icon: Icon(
  //               Icons.remove_circle_outline,
  //               size: 20,
  //               color: removable ? Colors.redAccent : Colors.grey,
  //             ),
  //             onPressed: removable ? onRemove : null, // 🔒 disable others
  //             tooltip: removable ? "Remove $title" : null,
  //           ),
  //         ],
  //       ],
  //     ),
  //   );
  // }
  Widget feeRowWithRemove({
    required String title,
    required num? amount,
    required bool removable,
    VoidCallback? onRemove,
    VoidCallback? onEdit,
  }) {
    if (amount == null || amount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// Amount Row (tap to edit)
          Expanded(
            child: InkWell(onTap: onEdit, child: feeRow(title, amount)),
          ),

          /// Action Icon (Edit OR Remove)
          if (widget.index != 1)
            IconButton(
              icon: Icon(
                onEdit != null
                    ? Icons.edit_outlined
                    : Icons.remove_circle_outline,
                size: 20,
                color: onEdit != null
                    ? const Color(0xFFBF955E)
                    : (removable ? Colors.redAccent : Colors.grey),
              ),
              onPressed: onEdit ?? (removable ? onRemove : null),
              tooltip: onEdit != null
                  ? "Edit $title"
                  : (removable ? "Remove $title" : null),
            ),
        ],
      ),
    );
  }

  Widget feeRowAdvance({required String title, required num? amount}) {
    if (amount == null || amount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// Amount Row (tap to edit)
          Expanded(child: InkWell(child: feeRow(title, amount))),
          if (widget.index != 1)
            IconButton(
              icon: Icon(Icons.check_circle, size: 22, color: Colors.green),
              onPressed: () {},
            ),
        ],
      ),
    );
  }

  Widget _subBillRowWithRemove({
    required String label,
    required num amount,
    required bool isDisabled,
    required VoidCallback onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text("• $label", style: const TextStyle(fontSize: 14)),
          ),
          Text("₹ ${amount.toStringAsFixed(0)}"),
          if (widget.index == 0)
            IconButton(
              icon: Icon(
                Icons.remove_circle_outline,
                size: 18,
                color: isDisabled ? Colors.grey : Colors.redAccent,
              ),
              onPressed: isDisabled ? null : onRemove,
              tooltip: isDisabled
                  ? "At least one option must remain"
                  : "Remove option",
            ),
        ],
      ),
    );
  }

  //////////////////////////////////////////////feee///////////////////////////
  Widget feeRow(String title, num? amount, {bool isTotal = false}) {
    if (amount == null || amount == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: isTotal ? 17 : 15,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: isTotal ? Colors.black : Colors.grey[800],
              ),
            ),
          ),
          Text(
            "₹ ${amount.toStringAsFixed(0)}",
            style: TextStyle(
              fontSize: isTotal ? 17 : 15,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? Colors.green[700] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(
    BuildContext context, {
    required int paymentId,
    required int consultationId,
    required String? staffId,
  }) {
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: Text(
                widget.fee['type'] == 'DAILYTREATMENTFEE'
                    ? "Pay Later Confirmation"
                    : "Cancel Confirmation",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Text(
                "Are you sure you want to ${widget.fee['type'] == 'DAILYTREATMENTFEE' ? 'Pay later' : 'cancel'} this payment and consultation?",
              ),
              actions: [
                /// ❌ CANCEL BUTTON
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(ctx),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.black),
                  ),
                ),

                /// ✅ OK BUTTON WITH LOADER
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() => isLoading = true);

                          try {
                            final dateTime = DateTime.now();

                            /// 🔹 Update Payment
                            await PaymentService().updatePayment(paymentId, {
                              'status':
                                  widget.fee['type'] == 'DAILYTREATMENTFEE'
                                  ? 'PAYLATER'
                                  : 'CANCELLED',
                              'staff_Id': staffId.toString(),
                              'updatedAt': dateTime.toString(),
                            });
                            if (widget.fee['type'] != 'DAILYTREATMENTFEE') {
                              widget.fee['type'] == 'ADMISSIONFEE'
                                  ? await ChargeService()
                                        .updateStatusByAdmission(
                                          admissionId: consultationId,
                                          status: 'CANCELLED',
                                        )
                                  :
                                    /// 🔹 Update Consultation
                                    await ConsultationService()
                                        .updateConsultation(consultationId, {
                                          'status': 'CANCELLED',
                                        });
                            }

                            if (context.mounted) {
                              Navigator.pop(ctx); // close dialog

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    widget.fee['type'] == 'DAILYTREATMENTFEE'
                                        ? " Pay later successfully"
                                        : "❌ Cancelled successfully",
                                  ),
                                  backgroundColor:
                                      widget.fee['type'] == 'DAILYTREATMENTFEE'
                                      ? Colors.blueAccent
                                      : Colors.redAccent,
                                ),
                              );
                              Navigator.pop(context, true);
                            }
                          } catch (e) {
                            setState(() => isLoading = false);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Failed to cancel"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "YES",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<pw.TableRow> buildFeeRows({
    required num registrationFee,
    required num consultationFee,
    required num emergencyFee,
    required num sugarTestFee,
  }) {
    final rows = <pw.TableRow>[];
    // 🔹 Section Header
    rows.add(
      pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 6, bottom: 10, left: 8),
            child: pw.Text(
              "Bill Details",
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(),
        ],
      ),
    );

    void addRow(String title, num? amount) {
      if (amount == null || amount == 0) return;

      rows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 6,
                horizontal: 8,
              ),
              child: pw.Text(
                title,
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey900),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 6,
                horizontal: 8,
              ),
              child: pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  "₹ ${amount.toStringAsFixed(0)}",
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 🔹 Fee Rows
    addRow("Registration Fee", registrationFee);
    addRow("Consultation Fee", consultationFee);
    addRow("Emergency Fee", emergencyFee);
    addRow("Sugar Test Fee", sugarTestFee);

    return rows;
  }

  // --- UI Helpers ---
  Widget _infoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "$label:",
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isEmpty ? "-" : value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // String _calculateTax(dynamic amount) {
  //   if (amount == null) return "0.00";
  //   double tax = (amount * 0.05);
  //   return tax.toStringAsFixed(0);
  // }

  // static String calculateTotal(dynamic amount) {
  //   if (amount == null) return "0.00";
  //   double total = (amount * 1.00);
  //   return total.toStringAsFixed(0);
  // }
  static double calculateTotal(dynamic amount) {
    if (amount == null) return 0.0;
    return (amount as num).toDouble();
  }

  static String extractString(dynamic value, [String? key]) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map && key != null) {
      return value[key]?.toString() ?? '';
    }
    return value.toString();
  }

  static String extractName(dynamic name) {
    if (name == null) return '';
    if (name is String) return name;
    if (name is Map) {
      final first = name['first'] ?? '';
      final last = name['last'] ?? '';
      return '$first $last'.trim();
    }
    return name.toString();
  }
}
