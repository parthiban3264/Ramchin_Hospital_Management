import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../Services/treatment_service.dart';
import '../NotificationsPage.dart';
import 'TreatmentPage.dart';

const Color primaryColor = Color(0xFFBF955E);

class TreatmentQueuePage extends StatefulWidget {
  const TreatmentQueuePage({super.key});

  @override
  State<TreatmentQueuePage> createState() => _TreatmentQueuePageState();
}

class _TreatmentQueuePageState extends State<TreatmentQueuePage>
    with SingleTickerProviderStateMixin {
  final TreatmentService _treatmentService = TreatmentService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _treatments = [];

  late final AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _fetchPendingTreatments();
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  Future<void> _fetchPendingTreatments() async {
    setState(() => _isLoading = true);
    try {
      final data = await _treatmentService.getAllTreatments();
      final all = (data['data'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final filtered = all.where((t) {
        final status = t['status']?.toString().toUpperCase();
        return status == 'PENDING' ||
            status == 'ONGOING' ||
            status == 'SCHEDULED';
      }).toList();

      filtered.sort((a, b) {
        const order = {'ONGOING': 1, 'PENDING': 2, 'SCHEDULED': 3};
        return (order[a['status']] ?? 99).compareTo(order[b['status']] ?? 99);
      });

      setState(() => _treatments = filtered);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching treatment queue: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ONGOING':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'SCHEDULED':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  /// Widget to show animated three dots for ongoing status
  Widget _statusWidget(String status) {
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
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: CircleAvatar(
                  radius: 4,
                  backgroundColor: index < dotCount
                      ? _statusColor(status)
                      : _statusColor(status).withValues(alpha: 0.3),
                ),
              ),
            ),
          );
        },
      );
    } else {
      return Text(
        status,
        style: TextStyle(
          color: _statusColor(status),
          fontWeight: FontWeight.w600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 100,
          decoration: const BoxDecoration(
            color: primaryColor,
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
                    'Treatment Queue',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _treatments.isEmpty
          ? Container(
              color: Colors.white,
              child: Center(
                child: Lottie.asset(
                  'assets/Lottie/NoData.json', // change path to your file
                  width: 400,
                  height: 320,
                  repeat: true,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchPendingTreatments,
              child: ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: _treatments.length,
                itemBuilder: (context, index) {
                  final t = _treatments[index];
                  final patient = t['Patient'];
                  final doctor = t['Doctor'];
                  final patientName = (patient is Map)
                      ? patient['name'] ?? t['patient_Id'] ?? '-'
                      : t['patient_Id'] ?? '-';
                  final doctorName = (doctor is Map)
                      ? doctor['name'] ?? t['doctor_Id'] ?? '-'
                      : t['doctor_Id'] ?? '-';
                  final status = (t['status'] is String)
                      ? t['status']!
                      : 'PENDING';
                  final startDate = (t['startDate'] is String)
                      ? t['startDate']
                      : '-';
                  final endDate = (t['endDate'] is String) ? t['endDate'] : '-';
                  final progress = t['progress'] ?? 'Not started';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    shadowColor: primaryColor.withValues(alpha: 0.3),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        if (status == 'PENDING' || status == 'ONGOING') {
                          // if (status == 'PENDING') {
                          //   final confirm = await showDialog<bool>(
                          //     context: context,
                          //     builder: (_) => AlertDialog(
                          //       title: const Text("Start Treatment?"),
                          //       content: Text(
                          //         "Do you want to start treatment for $patientName?",
                          //       ),
                          //       actions: [
                          //         TextButton(
                          //           onPressed: () =>
                          //               Navigator.pop(context, false),
                          //           child: const Text("Cancel"),
                          //         ),
                          //         ElevatedButton(
                          //           onPressed: () =>
                          //               Navigator.pop(context, true),
                          //           child: const Text("Start"),
                          //         ),
                          //       ],
                          //     ),
                          //   );
                          //
                          //   if (confirm == true) {
                          //     await _treatmentService.updateTreatment(t['id'], {
                          //       'status': 'ONGOING',
                          //     });
                          //     ScaffoldMessenger.of(context).showSnackBar(
                          //       const SnackBar(
                          //         content: Text(
                          //           "✅ Treatment started successfully",
                          //         ),
                          //       ),
                          //     );
                          //     _fetchPendingTreatments();
                          //   } else {
                          //     return;
                          //   }
                          // }
                          // Navigator.pop(context, true);
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TreatmentPage(treatment: t),
                            ),
                          );
                          _fetchPendingTreatments();
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: primaryColor.withValues(
                                    alpha: 0.15,
                                  ),
                                  child: const Icon(
                                    Icons.medical_services_rounded,
                                    color: primaryColor,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Patient: $patientName",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Doctor: $doctorName",
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(
                                      status,
                                    ).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: _statusWidget(status),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1, thickness: 0.8),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "Start: $startDate",
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.event_available,
                                  size: 16,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "End: $endDate",
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.timeline,
                                  size: 16,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "Progress: $progress",
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 13,
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
                },
              ),
            ),
    );
  }
}
