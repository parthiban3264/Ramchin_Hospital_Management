import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Pages/NotificationsPage.dart';
import '../../../Services/prescription_service.dart';
import '../../../services/consultation_service.dart';
import 'medical_fee_page.dart';

class MedicalQueuePage extends StatefulWidget {
  const MedicalQueuePage({super.key});

  @override
  State<MedicalQueuePage> createState() => _MedicalQueuePageState();
}

class _MedicalQueuePageState extends State<MedicalQueuePage>
    with TickerProviderStateMixin {
  final Color primaryColor = const Color(0xFFBF955E);

  late Future<List<dynamic>> consultationsFuture;
  List<dynamic> consultationsCache = [];
  bool firstLoad = true;

  //Timer? refreshTimer;
  late TabController topTabController;
  late TabController bottomTabController;

  int bottomTabIndex = 0; // Track selected bottom tab
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    topTabController = TabController(length: 2, vsync: this);
    bottomTabController = TabController(length: 2, vsync: this);
    consultationsFuture = _loadData();
    //_startAutoRefresh();
  }

  @override
  void dispose() {
    //refreshTimer?.cancel();
    topTabController.dispose();
    bottomTabController.dispose();
    super.dispose();
  }

  Future<List<dynamic>> _loadData() async {
    debugPrint('Loading medical prescriptions data...');
    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId') ?? '';
    debugPrint('Hospital ID: $hospitalId');

    final data = await PrescriptionService().getMedicalPrescriptions(
      hospitalId,
    );

    debugPrint('Loaded ${data.length} consultations');
    consultationsCache = data;
    return data;
  }

  @override
  Widget build(BuildContext context) {
    bool isQueueTab = bottomTabIndex == 0;
    bool isHistoryTab = bottomTabIndex == 1;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: _buildAppBar(),
      ),

      // ── BODY ──
      body: Column(
        children: [
          // TOP TABS → Today / Previous
          Material(
            color: Colors.white,
            elevation: 1,
            child: TabBar(
              controller: topTabController,
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: primaryColor,
              tabs: const [
                Tab(text: "Today"),
                Tab(text: "Previous"),
              ],
            ),
          ),
          if (topTabController.index == 1) _buildSearchBar(),
          // CONTENT AREA → patient list filtered by bottom tab
          Expanded(
            child: TabBarView(
              controller: topTabController,
              children: [
                _patientListView(isToday: true),
                _patientListView(isToday: false),
              ],
            ),
          ),
        ],
      ),

      // ── BOTTOM TABS (Queue / Paid / History) FIXED ──
      bottomNavigationBar: Material(
        color: Colors.white,
        elevation: 10,
        child: TabBar(
          controller: bottomTabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryColor,
          onTap: (index) {
            setState(() => bottomTabIndex = index);
          },
          tabs: const [
            Tab(text: "Queue"),
            Tab(text: "History"),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: "Search Patient Name or ID...",
          prefixIcon: const Icon(Icons.search, color: Color(0xFFBF955E)),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    searchController.clear();
                  },
                )
              : null,
        ),
      ),
    );
  }

  DateTime? _parseDateTime(String? dateString) {
    if (dateString == null) return null;
    try {
      // Handle format "2025-12-16 09:45 PM" or "2025-12-16T09:45:00.000Z"
      if (dateString.contains('T')) {
        return DateTime.parse(dateString);
      }

      final parts = dateString.split(' '); // ["2025-12-16", "09:45", "PM"]
      if (parts.length < 3) return null;

      final datePart = parts[0]; // "2025-12-16"
      final timePart = parts[1]; // "09:45"
      final ampm = parts[2]; // "PM"

      final timeParts = timePart.split(':');
      int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);

      if (ampm.toUpperCase() == 'PM' && hour != 12) hour += 12;
      if (ampm.toUpperCase() == 'AM' && hour == 12) hour = 0;

      final dateParts = datePart.split('-');
      return DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        hour,
        minute,
      );
    } catch (e) {
      return null;
    }
  }

  Widget _patientListView({required bool isToday}) {
    DateTime now = DateTime.now();
    DateTime todayStart = DateTime(now.year, now.month, now.day);
    DateTime twoDaysAgo = todayStart.subtract(const Duration(days: 5));

    List<dynamic> filteredList = consultationsCache.where((c) {
      final patient = c['patient'] ?? {};
      final patientName = (patient['name'] ?? '').toString().toLowerCase();
      final patientId = (c['patient_Id'] ?? '').toString().toLowerCase();

      final query = searchQuery.toLowerCase();

      // 1️⃣ SEARCH FILTER
      bool matchesSearch =
          query.isEmpty ||
          patientName.contains(query) ||
          patientId.contains(query);

      if (!matchesSearch) return false;

      // 2️⃣ DATE FILTER (CHECK CURRENT RECORD ONLY)
      final DateTime? prescriptionDate = _parseDateTime(c['created_at']);

      if (query.isEmpty && prescriptionDate != null) {
        if (isToday) {
          // TODAY TAB → only today
          if (prescriptionDate.isBefore(todayStart)) {
            return false;
          }
        } else {
          // PREVIOUS TAB → last 2 days excluding today
          if (!prescriptionDate.isBefore(todayStart) ||
              prescriptionDate.isBefore(twoDaysAgo)) {
            return false;
          }
        }
      }

      // 3️⃣ PAYMENT + MEDICINE FILTER
      final paymentStatus = (c['payment']?['status'] ?? '')
          .toString()
          .toUpperCase();

      final injectionRequested = c['consultation']?['medicineTonic'] == true;

      // 4️⃣ BOTTOM TAB FILTER
      if (bottomTabIndex == 0) {
        // ── QUEUE ──
        return injectionRequested && paymentStatus == 'PENDING';
      } else {
        // ── HISTORY ──
        return paymentStatus == 'PAID';
      }
    }).toList();

    // 5️⃣ SORT (Latest first by created_at of each record)
    filteredList.sort((a, b) {
      DateTime? dateA = _parseDateTime(a['created_at']);
      DateTime? dateB = _parseDateTime(b['created_at']);

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      return dateB.compareTo(dateA);
    });

    // 6️⃣ LOADER (FIRST LOAD)
    if (firstLoad) {
      return FutureBuilder<List<dynamic>>(
        future: consultationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFBF955E)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }

          firstLoad = false;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() {});
          });

          return const SizedBox.shrink();
        },
      );
    }

    // 7️⃣ EMPTY STATE
    if (filteredList.isEmpty) {
      return Center(
        child: Text(
          bottomTabIndex == 0
              ? 'No Medicines in queue.'
              : 'No history records found.',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );
    }

    // 8️⃣ BUILD LIST
    return _buildList(filteredList);
  }

  Widget _buildAppBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, const Color(0xFFD9B57A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                "Medical Queue",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.notifications,
                  color: Colors.white,
                  size: 26,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 UI LIST (unchanged)
  Widget _buildList(List<dynamic> consultations) {
    if (consultations.isEmpty) {
      return const Center(
        child: Text(
          'No patients in queue.',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: consultations.length,
      itemBuilder: (context, index) {
        final c = consultations[index];
        final patient = c['patient'];
        final name = patient?['name'] ?? 'Unknown';
        final patientId = c['patient_Id'].toString();
        final address = patient?['address']?['Address'] ?? 'N/A';
        final cell = patient?['phone']?['mobile'] ?? 'N/A';
        final doctor = c['consultation']['Doctor']?['name'] ?? 'Unknown Doctor';

        final prescriptionList = (consultationsCache as List?) ?? [];
        if (prescriptionList.isEmpty) {
          return const SizedBox.shrink(); // Skip records with no prescriptions
        }

        final payment = c['payment'] ?? {};
        bool hasPaid = payment['status'] == 'PAID';

        final bool medicineTonic =
            c['consultation']['medicineTonic'] == true ||
            c['consultation']['Injection'] == true;

        // If it's history tab or has paid, show paid view (1), else detailed view (0)
        int passIndexRow = (hasPaid || bottomTabIndex == 1) ? 1 : 0;

        return GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    MedicalFeePage(consultation: c, index: passIndexRow),
              ),
            );

            if (result == true) {
              final prefs = await SharedPreferences.getInstance();
              final hospitalId = prefs.getString('hospitalId') ?? '';
              final data = await PrescriptionService().getMedicalPrescriptions(
                hospitalId,
              );
              setState(() {
                consultationsCache = data;
              });
            }
          },
          child: _buildCard(
            name,
            patientId,
            cell,
            address,
            doctor,
            passIndexRow,
          ),
        );
      },
    );
  }

  /// 🔹 CARD UI (unchanged)
  Widget _buildCard(
    String name,
    String patientId,
    String cell,
    String address,
    String doctor,
    int passIndexRow,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 6,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
                gradient: LinearGradient(
                  colors: [primaryColor, const Color(0xFFD9B57A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      "#$patientId",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.phone_outlined, "Cell", cell),
                _buildInfoRow(Icons.home_outlined, "Address", address),
                _buildInfoRow(Icons.local_hospital_outlined, "Doctor", doctor),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (passIndexRow == 1) ...[
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      const Text("Paid", style: TextStyle(color: Colors.black)),
                      const Spacer(),
                    ],
                    const Text(
                      "Tap to view details →",
                      style: TextStyle(
                        color: Color(0xFFBF955E),
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            "$label:",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13.5, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// {
// "id": 119,
// "hospital_Id": 1,
// "prescription_no": "MEDI-1771483553561",
// "patient_Id": 2027,
// "doctor_Id": "1234567891",
// "consultation_Id": 4259,
// "payment_Id": 7861,
// "status": "PARTIALLY_DISPENSED",
// "notes": null,
// "follow_up_date": null,
// "valid_till": null,
// "created_at": "2026-02-19T06:45:53.568Z",
// "updated_at": "2026-02-21T06:43:26.958Z",
// "is_active": true,
// "patient": {
// "id": 2027,
// "hospital_Id": 1,
// "user_Id": "2553585899",
// "staff_Id": "1234567891",
// "name": "Mr. BHH",
// "ac_name": "",
// "phone": {
// "mobile": "+91 2553585899",
// "emergency": ""
// },
// "email": {
// "guardian": "",
// "personal": ""
// },
// "photo": "null",
// "status": "ACTIVE",
// "address": {
// "Address": "GG"
// },
// "dob": "1941-02-18T00:00:00.000Z",
// "gender": "Male",
// "bldGrp": "A+",
// "currentProblem": "",
// "medicalHistory": null,
// "tempCreatedAt": "2026-02-18T10:08:34.494Z",
// "createdAt": "2026-02-18 03:38 PM",
// "updatedAt": null
// },
// "payment": {
// "id": 7861,
// "hospital_Id": 1,
// "patient_Id": 2027,
// "staff_Id": "1234567891",
// "consultation_Id": 4259,
// "prescription_Id": null,
// "admission_Id": null,
// "reason": "Prescription Fee",
// "status": "PAID",
// "amount": 149.5,
// "received_Amount": null,
// "paymentType": "ManualPay",
// "type": "MEDICINETONICINJECTIONFEES",
// "transactionId": null,
// "billingId": null,
// "createdBy": null,
// "updategdBy": null,
// "createdAt": "2026-02-19 01:06 PM",
// "updatedAt": "2026-02-19 01:07 PM"
// },
// "consultation": {
// "id": 4259,
// "hospital_Id": 1,
// "patient_Id": 2027,
// "doctor_Id": "1234567891",
// "purpose": "",
// "tokenNo": 5,
// "tokenDate": "2026-02-18T00:00:00.000Z",
// "symptoms": false,
// "notes": null,
// "referredByDoctorName": null,
// "registrationFee": 200,
// "consultationFee": 200,
// "emergencyFee": 0,
// "sugarTestFee": 0,
// "cancelReason": null,
// "treatment": false,
// "patientType": "IP",
// "height": null,
// "weight": null,
// "BMI": null,
// "SPO2": null,
// "PK": null,
// "bp": null,
// "sugar": null,
// "isTestOnly": false,
// "emergency": false,
// "sugerTest": false,
// "sugerTestQueue": false,
// "temperature": 0,
// "medicineTonic": true,
// "Injection": false,
// "medicineQueue": "PENDING",
// "scanningTesting": false,
// "status": "ADMITTED",
// "queueStatus": "ONGOING",
// "access": null,
// "createdAt": "2026-02-18 03:38 PM",
// "updatedAt": "2026-02-21 03:10 PM",
// "abandonedAt": null,
// "paymentStatus": true
// },
// "medicines": [
// {
// "id": 144,
// "prescription_Id": 119,
// "medicine_Id": 1,
// "batch_No": "2",
// "hospital_Id": 1,
// "dosage": "1.0",
// "route": "TABLETS",
// "frequency": null,
// "days": 30,
// "total_quantity": 60,
// "total_amount": 156,
// "dispensed_quantity": 20,
// "after_food": true,
// "morning": true,
// "afternoon": false,
// "night": true,
// "instructions": null,
// "status": "PARTIALLY_DISPENSED",
// "created_at": "2026-02-19T06:45:53.856Z",
// "dispenses": [
// {
// "id": 108,
// "hospital_Id": 1,
// "prescription_medicine_Id": 144,
// "medicine_Id": 1,
// "batch_Id": 34,
// "amount": 52,
// "dispensed_days": 10,
// "dispensed_quantity": 20,
// "dispensed_by": 1234567891,
// "dispensed_at": "2026-02-19T06:45:54.292Z"
// }
// ],
// "medicine": {
// "id": 1,
// "hospital_Id": 1,
// "name": "paracitamol ",
// "category": "Tablets",
// "stock": 1561,
// "ndc_code": "",
// "reorder": 10,
// "is_active": true,
// "created_at": "2026-02-03T09:07:51.435Z",
// "order_status": "NOT_ORDERED",
// "batches": [
// {
// "id": 33,
// "hospital_Id": 1,
// "medicine_id": 1,
// "HSN": "G12",
// "batch_no": "1",
// "expiry_date": "2026-05-12T18:30:00.000Z",
// "manufacture_date": "2026-02-02T18:30:00.000Z",
// "total_stock": 0,
// "total_quantity": 105,
// "quantity": 100,
// "free_quantity": 5,
// "unit": 1,
// "rack_no": "10",
// "mrp": 10,
// "profit": 50,
// "purchase_price_unit": 5.05,
// "purchase_price_quantity": 5.05,
// "selling_price_quantity": 7.57,
// "selling_price_unit": 7.57,
// "purchase_details": {
// "base_amount": 500,
// "gst_percent": 1,
// "purchase_date": "2026-02-03T14:34:41.834183",
// "purchase_price": 505,
// "gst_per_quantity": 0.05,
// "total_gst_amount": 5,
// "rate_per_quantity": 5
// },
// "supplier_id": 1,
// "is_active": true,
// "created_at": "2026-02-03T09:07:51.618Z"
// },
// {
// "id": 34,
// "hospital_Id": 1,
// "medicine_id": 1,
// "HSN": "G13",
// "batch_no": "2",
// "expiry_date": "2026-05-04T18:30:00.000Z",
// "manufacture_date": "2026-02-02T18:30:00.000Z",
// "total_stock": 1711,
// "total_quantity": 500,
// "quantity": 358,
// "free_quantity": 0,
// "unit": 5,
// "rack_no": "10e",
// "mrp": 15,
// "profit": 20,
// "purchase_price_unit": 2.2,
// "purchase_price_quantity": 11,
// "selling_price_quantity": 13.2,
// "selling_price_unit": 2.63,
// "purchase_details": {
// "base_amount": 5000,
// "gst_percent": 10,
// "purchase_date": "2026-02-03T00:00:00.000",
// "purchase_price": 5500,
// "gst_per_quantity": 1,
// "total_gst_amount": 500,
// "rate_per_quantity": 10
// },
// "supplier_id": 1,
// "is_active": true,
// "created_at": "2026-02-03T09:13:03.789Z"
// }
// ]
// }
// },
