import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../Pages/NotificationsPage.dart';
import '../../../../Pages/payment_modal.dart';
import '../../../../Services/consultation_service.dart';
import '../../../../Services/payment_service.dart';
import '../../../../Services/socket_service.dart';
import '../../../../Services/testing&scanning_service.dart';

class FeesPaymentPage extends StatefulWidget {
  final Map<String, dynamic> fee;
  final Map<String, dynamic> patient;
  final int index;

  const FeesPaymentPage({
    super.key,
    required this.fee,
    required this.patient,
    required this.index,
  });

  @override
  State<FeesPaymentPage> createState() => _FeesPaymentPageState();
}

class _FeesPaymentPageState extends State<FeesPaymentPage> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  bool _isProcessing = false;
  final socketService = SocketService();
  String? logo;
  String? hospitalName;
  String? hospitalPlace;

  late TextEditingController cellController;
  late TextEditingController nameController;
  late TextEditingController addressController;
  late TextEditingController dobController;
  late TextEditingController feeController;

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
    addressController = TextEditingController(
      text: extractString(widget.patient['address'], 'Address'),
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
    logo = await secureStorage.read(key: 'hospitalPhoto');
    hospitalName = await secureStorage.read(key: 'hospitalName');
    hospitalPlace = await secureStorage.read(key: 'hospitalPlace');
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

  String calculateAge(String? dob) {
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

  String getFormattedDate(dynamic value) {
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
      print("Date parse error: $e");
      return value.toString();
    }
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

    if (paymentResult == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment cancelled')));
      return;
    }
    final String paymentMode = paymentResult['paymentMode'] ?? 'unknown';

    // ✅ Payment succeeded → update backend
    setState(() => _isProcessing = true);
    final Staff_Id = await secureStorage.read(key: 'userId');
    final response = await PaymentService().updatePayment(paymentId, {
      'status': 'PAID',
      // 'transactionId': paymentResult['transactionId'],
      "staff_Id": Staff_Id.toString(),
      "paymentType": paymentMode,
      "updatedAt": _dateTime.toString(),
    });
    print("patienttt${widget.patient}");
    print("ffgjg${widget.fee}");
    final Id = widget.patient['Consultation']?[0]?['id'];
    final consultationId = widget.fee['consultation_Id'];

    print(consultationId);
    print(type);
    if (type == 'REGISTRATIONFEE') {
      await ConsultationService().updateConsultation(consultationId, {
        "paymentStatus": true,
      });
    } else if (type == 'TESTINGFEESANDSCANNINGFEE') {
      final testings = widget.fee['TestingAndScanningPatients'];

      final testId = (testings != null && testings.isNotEmpty)
          ? testings[0]['payment_Id']
          : null;
      print(testId);
      await TestingScanningService().updateTestAndScan(testId);
      await ConsultationService().updateConsultation(consultationId, {
        "queueStatus": 'PENDING',
      });
    } else {
      print('Invalid type');
    }
    // else if (type == 'MEDICINEFEEANDINJECTIONFEE') {
    // await ConsultationService().updateConsultation(Id, {
    // "paymentStatus": true,
    // });
    // }

    setState(() => _isProcessing = false);

    if (response != null && response['status'] == 'success') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Payment Successful')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Failed to update payment status.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List tests = widget.fee["TestingAndScanningPatients"] ?? [];

    final Color themeColor = const Color(0xFFBF955E);
    const Color background = Color(0xFFF8F8F8);

    return Scaffold(
      backgroundColor: background,
      appBar: PreferredSize(
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
                color: Colors.black.withOpacity(0.15),
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
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
                  _infoRow("Cell No ", cellController.text),
                  _infoRow("DOB ", dobController.text),
                  _infoRow("AGE ", calculateAge(dobController.text)),
                  _infoRow("Address ", addressController.text),
                  const Divider(thickness: 1.2, height: 30),

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
                  const Divider(thickness: 1.5, height: 25),
                  const SizedBox(height: 12),
                  if (widget.fee['type'] == 'REGISTRATIONFEE') ...[
                    Row(
                      children: [
                        Text(
                          "${widget.fee['reason']}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        Text(
                          "₹ ${feeController.text}",
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),

                    // _billRow(
                    //   "${widget.fee['reason']}",
                    //   "₹ ${feeController.text}",
                    // ),
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

                    ...tests.map((t) {
                      final title = t["title"]?.toString() ?? "-";
                      final amount = t["amount"]?.toString() ?? "0";

                      return _billRow(title, "₹ $amount");
                    }).toList(),
                  ],

                  // _billRow("Discount", "₹0.00"),
                  // _billRow(
                  //   "Tax (5%)",
                  //   "₹${_calculateTax(widget.fee['amount'])}",
                  // ),

                  // 💳 Fee Details
                  // Center(
                  //   child: const Text(
                  //     "Fee Summary",
                  //     style: TextStyle(
                  //       fontWeight: FontWeight.w600,
                  //       fontSize: 16,
                  //       color: Colors.black87,
                  //     ),
                  //   ),
                  // ),
                  // const Divider(thickness: 1.5, height: 25),
                  // const SizedBox(height: 12),
                  //
                  // if (widget.fee['type'] == 'REGISTRATIONFEE') ...[
                  //   _billRow("Registration Fee", "₹ ${feeController.text}"),
                  // ] else if (widget.fee['type'] ==
                  //     'TESTINGFEESANDSCANNINGFEE') ...[
                  //   Text(
                  //     "${widget.fee['reason']}",
                  //     style: const TextStyle(
                  //       fontSize: 15,
                  //       fontWeight: FontWeight.w500,
                  //       color: Colors.black87,
                  //     ),
                  //   ),
                  //   const SizedBox(height: 8),
                  //   if (widget.patient['TestingAndScanning']?['selectedOptions'] !=
                  //           null &&
                  //       widget
                  //           .patient['TestingAndScanning']?['selectedOptions']
                  //           .isNotEmpty)
                  //     ...widget
                  //         .patient['TestingAndScanning']?['selectedOptions']
                  //         .map<Widget>(
                  //           (test) => _billRow(
                  //             test['name'] ?? 'Unknown Test',
                  //             "₹ ${(test['amount'] ?? 0).toString()}",
                  //           ),
                  //         )
                  //         .toList()
                  //   else
                  //     const Text(
                  //       "No tests or scans selected.",
                  //       style: TextStyle(color: Colors.grey),
                  //     ),
                  //   const Divider(thickness: 1.2, height: 25),
                  //   _billRow("Total", "₹ ${feeController.text}"),
                  // ] else ...[
                  //   _billRow(
                  //     "${widget.fee['reason']}",
                  //     "₹ ${feeController.text}",
                  //   ),
                  // ],
                  const Divider(thickness: 1.5, height: 25),

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
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "Total : ₹ ${_calculateTotal(widget.fee['amount'])}",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // 💰 Pay Button
                  widget.index == 0
                      ? Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: _isProcessing ? 160 : 200,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
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
                                  : const Text(
                                      "Pay Bill",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                              onPressed: _isProcessing ? null : _handlePayment,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // 🔹 Print Button
                            ElevatedButton.icon(
                              onPressed: () async {
                                final pdf = await _buildPdf();
                                await Printing.layoutPdf(
                                  onLayout: (format) async => pdf.save(),
                                );
                              },
                              icon: const Icon(
                                Icons.print,
                                color: Colors.white,
                              ),
                              label: const Text(
                                "Print",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent.shade400,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5,
                              ),
                            ),

                            // 🔹 Share Button
                            ElevatedButton.icon(
                              onPressed: () async {
                                final pdf = await _buildPdf();
                                await Printing.sharePdf(
                                  bytes: await pdf.save(),
                                  filename: "hospital_bill.pdf",
                                );
                              },

                              icon: const Icon(
                                Icons.share,
                                color: Colors.white,
                              ),
                              label: const Text(
                                "Share",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5,
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),

          // 🌀 Loading Overlay
          if (_isProcessing)
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

  Future<pw.Document> _buildPdf() async {
    final ttf = await PdfGoogleFonts.notoSansRegular();
    final ttfBold = await PdfGoogleFonts.notoSansBold();
    final pdf = pw.Document();

    final logoo = pw.MemoryImage((await http.get(Uri.parse(logo!))).bodyBytes);

    final blue = PdfColor.fromHex("#0A3D91");
    final lightBlue = PdfColor.fromHex("#1E5CC4");

    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
        // margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ------------------------ HEADER ------------------------
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "$hospitalName",
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: blue,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        "$hospitalPlace",
                        style: pw.TextStyle(fontSize: 11),
                      ),
                      pw.Text(
                        "Accurate  |  Caring  |  Instant",
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColor.fromInt(0x777777),
                        ),
                      ),
                    ],
                  ),

                  pw.Container(
                    color: PdfColors.white,
                    height: 50,
                    width: 120,
                    child: pw.ClipRect(
                      child: pw.FittedBox(
                        fit: pw.BoxFit.cover,
                        child: pw.Image(logoo),
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 18),
              pw.Divider(),
              pw.SizedBox(height: 18),

              // ------------------------ PATIENT INFO BOX ------------------------
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  borderRadius: pw.BorderRadius.circular(10),
                  border: pw.Border.all(color: PdfColor.fromHex("#D9D9D9")),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: [
                    // LEFT SIDE
                    pw.Expanded(
                      flex: 1,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "Name: ${nameController.text}",
                            style: pw.TextStyle(fontSize: 11),
                          ),
                          pw.Text(
                            "PID: ${widget.fee['Patient']['user_Id']}",
                            style: pw.TextStyle(fontSize: 11),
                          ),
                          pw.Text(
                            "Phone: ${cellController.text}",
                            style: pw.TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),

                    // RIGHT SIDE
                    pw.Expanded(
                      flex: 1,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            "Age: ${calculateAge(dobController.text)}",
                            style: pw.TextStyle(fontSize: 11),
                          ),
                          pw.Text(
                            "Sex: ${widget.fee['Patient']['gender']}",
                            style: pw.TextStyle(fontSize: 11),
                          ),
                          pw.Text(
                            "Date: ${getFormattedDate(DateTime.now().toString())}",
                            style: pw.TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // ------------------------ TEST TITLE BAR ------------------------
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                decoration: pw.BoxDecoration(
                  gradient: pw.LinearGradient(colors: [blue, lightBlue]),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Center(
                  child: pw.Text(
                    widget.fee['reason'].toString().toUpperCase(),
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),

              pw.SizedBox(height: 20),

              // ------------------------ TABLE HEADER ------------------------
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey300,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColors.grey600, width: 1),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        "Service / Test",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Align(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text(
                          "Amount (₹)",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 6),

              // Registration Fee
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        "${widget.fee['reason']}", // Registration or Consultation
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Align(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text(
                          "₹ ${widget.fee['amount']}",
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.Divider(),

              pw.SizedBox(height: 4),

              // Tests List
              if (widget.fee['TestingAndScanningPatients'] != null)
                ...widget.fee['TestingAndScanningPatients'].map<pw.Widget>((t) {
                  return pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 6),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            "${t['title']}",
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Align(
                            alignment: pw.Alignment.centerRight,
                            child: pw.Text(
                              "₹ ${t['amount']}",
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

              pw.SizedBox(height: 12),

              // ------------------------ TOTAL ------------------------
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  "TOTAL : ₹ ${_calculateTotal(widget.fee['amount'])}",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: blue,
                  ),
                ),
              ),

              pw.SizedBox(height: 30),

              // ------------------------ FOOTER ------------------------
              pw.Center(
                child: pw.Text(
                  "Thank you for choosing Green Valley Hospital",
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: PdfColor.fromInt(0x666666),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
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

  Widget _billRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  String _calculateTax(dynamic amount) {
    if (amount == null) return "0.00";
    double tax = (amount * 0.05);
    return tax.toStringAsFixed(0);
  }

  String _calculateTotal(dynamic amount) {
    if (amount == null) return "0.00";
    double total = (amount * 1.00);
    return total.toStringAsFixed(0);
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
