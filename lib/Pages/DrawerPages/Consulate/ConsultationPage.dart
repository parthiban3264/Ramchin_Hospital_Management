import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../../../Services/consultation_service.dart';
import '../../NotificationsPage.dart';
import 'doctor_consultation_page.dart';
import 'package:lottie/lottie.dart';

const Color customGold = Color(0xFFBF955E);

class ConsultationQueuePage extends StatefulWidget {
  const ConsultationQueuePage({Key? key}) : super(key: key);

  @override
  State<ConsultationQueuePage> createState() => _ConsultationQueuePageState();
}

class _ConsultationQueuePageState extends State<ConsultationQueuePage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> consultations = [];
  bool _isLoading = false;

  late final AnimationController _dotController;

  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _fetchAllConsultations();
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllConsultations() async {
    setState(() => _isLoading = true);
    try {
      final response = await ConsultationService().getAllConsultations();
      final List<dynamic> rawList = response;

      // Read role and userid from secure storage
      final role = await secureStorage.read(key: 'role') ?? '';
      final userId = await secureStorage.read(key: 'userId') ?? '';
      print('Role: $role, User ID: $userId');

      // Filter by role and status
      List filteredList = rawList.where((item) {
        final status = (item['status'] ?? '').toString().toUpperCase();
        if (status != 'PENDING' && status != 'ONGOING') return false;

        if (role.toLowerCase() == 'admin') {
          // Admin sees all
          return true;
        } else if (role.toLowerCase() == 'medical staff') {
          // Medical staff sees only their consultations by doctor_Id == userId
          final doctorUserId = (item['doctor_Id'] ?? '').toString();
          return doctorUserId == userId;
        }
        return false;
      }).toList();

      // Sort to have ONGOING first
      filteredList.sort((a, b) {
        final statusA = (a['status'] ?? '').toString().toUpperCase();
        final statusB = (b['status'] ?? '').toString().toUpperCase();
        if (statusA == statusB) return 0;
        if (statusA == 'ONGOING') return -1;
        if (statusB == 'ONGOING') return 1;
        return 0;
      });

      consultations = filteredList.map<Map<String, dynamic>>((item) {
        final patient = item['Patient'] ?? {};
        final doctor = item['Doctor'] ?? {};
        final hospital = item['Hospital'] ?? {};

        return {
          'id': item['id'],
          'appointdate': item['appointdate'],
          'purpose': item['purpose'] ?? '-',
          'status': item['status'] ?? 'WAITING',
          'patientName': patient['name'] ?? '-',
          'gender': patient['gender'] ?? '-',
          'dob': patient['dob'] ?? '-',
          'Blood Group': patient['bldGrp'] ?? '-',
          'Bp': patient['bp'] ?? '-',
          'Sugar': patient['sugar'] ?? '-',
          'doctor_Id': item['doctor_Id'] ?? '-',
          'doctorName': doctor['name'] ?? '-',
          'hospitalName': hospital['name'] ?? '-',
          'patient_Id': patient['user_Id'] ?? '-',
          'hospital_Id': hospital['id'],
        };
      }).toList();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error fetching consultations: $e')),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleTap(Map<String, dynamic> consultation) async {
    final status = consultation['status'].toString().toUpperCase();

    if (status == 'PENDING' || status == 'WAITING') {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⏳ Updating status to ONGOING...")),
        );

        final response = await ConsultationService().updateConsultation(
          consultation['id'],
          {"status": "ONGOING"},
        );

        if (response['status'] == 'success' ||
            response['message']?.toString().toLowerCase().contains('updated') ==
                true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Status updated to ONGOING")),
          );
          await _fetchAllConsultations(); // Refresh page
          consultation = consultations.firstWhere(
            (c) => c['id'] == consultation['id'],
            orElse: () => consultation,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("⚠️ Update failed: ${response['message']}")),
          );
          return;
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Error updating status: $e")));
        return;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorConsultationPage(consultation: consultation),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ONGOING':
        return Colors.white;
      case 'COMPLETED':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Widget _buildStatusText(String status) {
  //   if (status.toUpperCase() == 'ONGOING') {
  //     return AnimatedBuilder(
  //       animation: _dotController,
  //       builder: (context, child) {
  //         int dotCount = ((_dotController.value * 3).floor() % 3) + 1;
  //         return Row(
  //           mainAxisSize: MainAxisSize.min,
  //           children: List.generate(
  //             3,
  //             (index) => Padding(
  //               padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
  //               child: CircleAvatar(
  //                 radius: 4,
  //                 backgroundColor: index < dotCount
  //                     ? Colors.white
  //                     : Colors.white24,
  //               ),
  //             ),
  //           ),
  //         );
  //       },
  //     );
  //   }
  //   return Text(
  //     status.toUpperCase(),
  //     style: const TextStyle(
  //       color: Colors.white,
  //       fontSize: 12,
  //       fontWeight: FontWeight.bold,
  //     ),
  //   );
  //}
  Widget _buildStatusText(String status) {
    final upperStatus = status.toUpperCase();

    if (upperStatus == 'ONGOING') {
      // 👇 Use your Lottie loading animation here
      return Lottie.asset(
        'assets/Lottie/blue loading.json', // change path to your file
        width: 100,
        height: 80,
        repeat: true,
      );
    }

    return Text(
      upperStatus,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildConsultationQueue() {
    if (consultations.isEmpty) {
      return Center(
        child: Lottie.asset(
          'assets/Lottie/NoData.json', // change path to your file
          width: 100,
          height: 80,
          repeat: true,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAllConsultations,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: consultations.length,
        itemBuilder: (context, index) {
          final c = consultations[index];
          final appointDate = DateTime.tryParse(c['appointdate'] ?? '');
          final formattedTime = appointDate != null
              ? DateFormat('MMM dd, yyyy • hh:mm a').format(appointDate)
              : '-';

          return GestureDetector(
            onTap: () => _handleTap(c),
            child: Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              shadowColor: Colors.black26,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.grey.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: customGold.withOpacity(0.2),
                          child: const Icon(Icons.person, color: customGold),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c['patientName'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "ID: ${c['patient_Id'] ?? '-'}",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          // padding: const EdgeInsets.symmetric(
                          //   horizontal: 10,
                          //   vertical: 4,
                          // ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(c['status']),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _buildStatusText(c['status']),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Divider(thickness: 0.5, color: Colors.grey),
                    const SizedBox(height: 6),
                    _buildInfoRow(
                      Icons.local_hospital,
                      "Hospital",
                      c['hospitalName'],
                    ),
                    _buildInfoRow(Icons.event, "Date & Time", formattedTime),
                    _buildInfoRow(Icons.info_outline, "Purpose", c['purpose']),
                    _buildInfoRow(Icons.person_outline, "Gender", c['gender']),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _handleTap(c),
                        icon: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: customGold,
                        ),
                        label: const Text(
                          "Start Consultation",
                          style: TextStyle(
                            color: customGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 18, color: customGold),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: customGold,
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
                    "Consultation Queue",
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
                ],
              ),
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF8F8F8),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: customGold))
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: _buildConsultationQueue(),
            ),
    );
  }
}
