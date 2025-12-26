import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../Services/consultation_service.dart';
import '../../NotificationsPage.dart';

const Color customGold = Color(0xFFBF955E);

class ReceptionQueuePage extends StatefulWidget {
  const ReceptionQueuePage({super.key});

  @override
  State<ReceptionQueuePage> createState() => _ReceptionQueuePageState();
}

class _ReceptionQueuePageState extends State<ReceptionQueuePage>
    with SingleTickerProviderStateMixin {
  late Future<List<dynamic>> consultationsFuture;
  late AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    consultationsFuture = ConsultationService.getAllReceptionConsultations();

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  Future<void> _refreshList() async {
    setState(() {
      consultationsFuture = ConsultationService.getAllReceptionConsultations();
    });
  }

  Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return customGold;
      case 'ONGOING':
        return Colors.blue.shade600;
      case 'COMPLETED':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade400;
    }
  }

  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return '-';
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dt);
  }

  Widget buildStatusWidget(String status) {
    if (status.toUpperCase() == 'ONGOING') {
      return AnimatedBuilder(
        animation: _dotController,
        builder: (context, child) {
          int dotCount = ((_dotController.value * 3).floor() % 3) + 1;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: CircleAvatar(
                  radius: 4,
                  backgroundColor: index < dotCount
                      ? Colors.white
                      : Colors.white24,
                ),
              ),
            ),
          );
        },
      );
    } else {
      return Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 18, color: customGold),
          const SizedBox(width: 6),
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.black87,
            ),
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

  Widget _buildReceptionQueue(List<dynamic> consultations) {
    if (consultations.isEmpty) {
      return const Center(
        child: Text(
          'No consultations found',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );
    }

    final filtered = consultations.where((item) {
      final status = (item['status'] ?? '').toString().toUpperCase();
      return status == 'ONGOING' || status == 'PENDING';
    }).toList();

    return RefreshIndicator(
      onRefresh: _refreshList,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final item = filtered[index];
          final patient = item['Patient'] ?? {};
          final doctor = item['Doctor'] ?? {};
          final hospital = item['Hospital'] ?? {};

          final patientName = patient['name'] ?? '-';
          final doctorName = doctor['name'] ?? '-';
          final hospitalName = hospital['name'] ?? '-';
          final purpose = item['purpose'] ?? '-';
          final status = (item['status'] ?? '-').toString();
          final formattedTime = formatDate(item['appointdate']);
          final badgeColor = getStatusColor(status);

          final initials = patientName.isNotEmpty
              ? patientName.split(' ').map((e) => e[0]).take(2).join()
              : 'P';

          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top: Patient + Status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white24,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patientName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hospitalName,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: buildStatusWidget(status),
                      ),
                    ],
                  ),
                ),
                // Bottom: Details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        Icons.medical_services,
                        "Doctor",
                        doctorName,
                      ),
                      _buildInfoRow(Icons.description, "Purpose", purpose),
                      _buildInfoRow(Icons.schedule, "Appt", formattedTime),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
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
                    "Reception Queue",
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
      body: FutureBuilder<List<dynamic>>(
        future: consultationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: customGold),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No consultations found',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(8),
            child: _buildReceptionQueue(snapshot.data!),
          );
        },
      ),
    );
  }
}
