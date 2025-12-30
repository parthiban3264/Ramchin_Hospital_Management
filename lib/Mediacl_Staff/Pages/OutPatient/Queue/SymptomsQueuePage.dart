import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import '../../../../Pages/NotificationsPage.dart';
import '../../../../Services/payment_service.dart';
import '../Page/SymptomsPage.dart';

class SymptomsQueuePage extends StatefulWidget {
  const SymptomsQueuePage({Key? key}) : super(key: key);

  @override
  _SymptomsQueuePageState createState() => _SymptomsQueuePageState();
}

class _SymptomsQueuePageState extends State<SymptomsQueuePage> {
  late Future<List<dynamic>> futurePatients;
  final Color primaryColor = const Color(0xFFBF955E);

  @override
  void initState() {
    super.initState();
    futurePatients = PaymentService().getAllPaid();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "N/A";
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String formatDob(String? dob) {
    if (dob == null || dob.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dob);
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (_) {
      return dob;
    }
  }

  String calculateAge(String? dob) {
    if (dob == null || dob.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dob);
      final now = DateTime.now();
      int age = now.year - date.year;
      if (now.month < date.month ||
          (now.month == date.month && now.day < date.day)) {
        age--;
      }
      return "$age ";
    } catch (_) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    print('futures $futurePatients');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
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
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "Vitals Queue",
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
                ],
              ),
            ),
          ),
        ),
      ),

      // 🔹 MAIN BODY
      body: FutureBuilder<List<dynamic>>(
        future: futurePatients,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Lottie.asset(
                'assets/Lottie/error404.json',
                width: 280,
                height: 280,
                fit: BoxFit.contain,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/Lottie/NoData.json',
                    width: 250,
                    height: 250,
                    repeat: true,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No patients in Vitals queue",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
            );
          }

          final patients = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final item = patients[index];
              print('item $item');
              final consultationId = item['consultation_Id'];
              final consultationData = item['Consultation'];
              final tokenNo =
                  (consultationData['tokenNo'] == null ||
                      consultationData['tokenNo'] == 0)
                  ? '-'
                  : consultationData['tokenNo'].toString();
              final sugarData = item['Consultation']['sugerTest'] ?? false;
              print('sugarData $sugarData');
              final patient = item['Patient'] ?? <String, dynamic>{};
              final createdAt = item['createdAt'];
              final sugar = item['Consultation']['sugar'].toString();

              return GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SymptomsPage(
                        patient: patient,
                        consultationId: consultationId,
                        sugarData: sugarData,
                        sugar: sugar,
                        consultationData: consultationData,
                        mode: 1,
                      ),
                    ),
                  );
                  if (result == true) {
                    setState(() {
                      futurePatients = PaymentService().getAllPaid();
                    });
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.15),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          (patient['name'] ?? 'Unknown').toString(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        //crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
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
                      const SizedBox(height: 5),

                      // Divider
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 250,
                          height: 2,
                          color: primaryColor.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Details
                      _infoRow(
                        Icons.badge_outlined,
                        "ID",
                        (patient['id'] ?? 'N/A').toString(),
                      ),

                      // ✅ DOB & Age in ONE ROW
                      Row(
                        children: [
                          Icon(
                            Icons.cake_outlined,
                            size: 20,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'DOB: ${formatDob(getString(patient['dob']))} ',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Spacer(),
                          Text(
                            'AGE: ${calculateAge(getString(patient['dob']))} ',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      _infoRow(
                        Icons.wc_outlined,
                        "Gender",
                        (patient['gender'] ?? 'N/A').toString(),
                      ),
                      _infoRow(
                        Icons.access_time_outlined,
                        "Created",
                        _formatDate(createdAt),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: primaryColor.withValues(alpha: 0.8), size: 18),
          const SizedBox(width: 10),
          Text(
            "$label:",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54, fontSize: 14.5),
            ),
          ),
        ],
      ),
    );
  }

  static String getString(dynamic value) {
    if (value == null) return '-';
    if (value is String) return value;
    return value.toString();
  }
}
