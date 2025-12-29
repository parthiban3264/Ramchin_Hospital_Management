import 'package:flutter/material.dart';

import '../../../../Pages/NotificationsPage.dart';
import '../../../../Services/consultation_service.dart';
import '../Page/InjectionPage.dart';

class InjectionQueuePage extends StatefulWidget {
  const InjectionQueuePage({super.key});

  @override
  State<InjectionQueuePage> createState() => _InjectionQueuePageState();
}

class _InjectionQueuePageState extends State<InjectionQueuePage> {
  final Color primaryColor = const Color(0xFFBF955E);
  late Future<List<dynamic>> consultationsFuture;

  @override
  void initState() {
    super.initState();
    consultationsFuture = ConsultationService.getAllConsultationByMedical(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor],
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
                    "Injection Queue",
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

          final consultations = (snapshot.data ?? []).where((c) {
            final injections = c['InjectionPatient'] as List?;
            if (injections == null || injections.isEmpty) return false;

            // Check if any injection is NOT cancelled
            final hasValidInjection = injections.any(
              (inj) => inj['status'] != 'CANCELLED',
            );

            return hasValidInjection;
          }).toList();

          if (consultations.isEmpty) {
            return const Center(
              child: Text(
                'No patients in queue.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: consultations.length,
            itemBuilder: (context, index) {
              final c = consultations[index];
              final patient = c['Patient'];
              final name = patient?['name'] ?? 'Unknown';
              final patientId = c['patient_Id'] ?? '';
              final address = patient?['address']?['Address'] ?? 'N/A';
              final cell = patient?['phone']?['mobile'] ?? 'N/A';
              final doctor = c['Doctor']?['name'] ?? 'Unknown Doctor';
              // final queueStatus = c['queueStatus'] ?? 'PENDING';
              // final statusColor = queueStatus == 'COMPLETED'
              //     ? Colors.green
              //     : queueStatus == 'ONGOING'
              //     ? Colors.orange
              //     : Colors.blueGrey;

              return GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InjectionPage(consultation: c),
                    ),
                  );
                  if (result == true) {
                    setState(() {
                      consultationsFuture =
                          ConsultationService.getAllConsultationByMedical(1);
                    });
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(vertical: 10),
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
                      // Left gradient accent bar
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
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Patient avatar
                            // CircleAvatar(
                            //   radius: 28,
                            //   backgroundColor: Colors.grey[200],
                            //   child: const Icon(
                            //     Icons.person_outline,
                            //     size: 30,
                            //     color: Colors.black54,
                            //   ),
                            // ),
                            const SizedBox(width: 16),

                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Patient name
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

                                      // Patient ID
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
                                  _buildInfoRow(
                                    Icons.phone_outlined,
                                    "Cell",
                                    cell,
                                  ),
                                  _buildInfoRow(
                                    Icons.home_outlined,
                                    "Address",
                                    address,
                                  ),
                                  _buildInfoRow(
                                    Icons.local_hospital_outlined,
                                    "Doctor",
                                    doctor,
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Text(
                                      "Tap to view details →",
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
