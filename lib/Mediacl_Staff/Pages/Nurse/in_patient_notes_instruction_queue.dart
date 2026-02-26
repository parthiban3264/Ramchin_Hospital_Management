import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Pages/NotificationsPage.dart';
import '../../../../Services/admin_service.dart';
import '../../../../Services/consultation_service.dart';
import '../Page/injection_page.dart';

class InjectionNotesAndInstructionQueuePage extends StatefulWidget {
  const InjectionNotesAndInstructionQueuePage({super.key});

  @override
  State<InjectionNotesAndInstructionQueuePage> createState() =>
      _InjectionNotesAndInstructionQueuePageState();
}

class _InjectionNotesAndInstructionQueuePageState
    extends State<InjectionNotesAndInstructionQueuePage> {
  final Color primaryColor = const Color(0xFFBF955E);
  late Future<List<dynamic>> consultationsFuture;
  int _selectedTabIndex = 0; // 0: OP, 1: IP

  @override
  void initState() {
    super.initState();
    consultationsFuture = ConsultationService.getAllConsultationByMedical(1);
    loadUserId();
    _loadNurseAndDefault();
  }

  String? _currentUserId;
  String? selectedNurseId;
  List<dynamic> nurse = [];

  Future<void> loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('userId');
    setState(() {});
  }

  Future<void> _loadNurseAndDefault() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('userId');

    final staff = await AdminService().getMedicalStaff();

    nurse = staff
        .where(
          (n) => (n['role'] ?? '').toString().toLowerCase().contains('nurse'),
        )
        .toList();
  }

  /// consultationsFuture['Consultation']['patientType'] =='OP' or 'IP'
  @override
  Widget build(BuildContext context) {
    print('consultationsFuture $consultationsFuture');
    return Scaffold(
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildTabButton("OP Patients", 0),
                const SizedBox(width: 16),
                _buildTabButton("IP Patients", 1),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 90,
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

          // final consultations = (snapshot.data ?? []).where((c) {
          //   // 1. Check valid injections
          //   final injections = c['Prescription'] as List?;
          //   if (injections == null || injections.isEmpty) return false;
          //
          //   final hasValidInjection = injections.any(
          //     (inj) => inj['status'] != 'CANCELLED',
          //   );
          //   if (!hasValidInjection) return false;
          //
          //   // 2. Get last nurse ID safely
          //   final staffChanges = c['Admission']?[0]?['staffChange'] as List?;
          //   final lastNurseId = staffChanges != null && staffChanges.isNotEmpty
          //       ? staffChanges.last['nurse']?.toString()
          //       : null;
          //
          //   // 3. Patient type
          //   final pType =
          //       c['patientType']?.toString().toUpperCase() ??
          //       c['Consultation']?['patientType']?.toString().toUpperCase() ??
          //       '';
          //
          //   if (_selectedTabIndex == 0) {
          //     return pType == 'OP';
          //   } else {
          //     return pType == 'IP' && lastNurseId == _currentUserId;
          //   }
          // }).toList();
          final consultations = (snapshot.data ?? []).where((c) {
            // Valid injections
            final injections = c['Prescription'] as List?;
            if (injections == null || injections.isEmpty) return false;

            if (!injections.any((inj) => inj['status'] != 'CANCELLED')) {
              return false;
            }

            // Patient type
            final pType =
                c['patientType']?.toString().toUpperCase() ??
                c['Consultation']?['patientType']?.toString().toUpperCase() ??
                '';

            if (_selectedTabIndex == 0) {
              return pType == 'OP';
            }

            if (pType != 'IP') return false;

            final staffChanges = c['Admission']?[0]?['staffChange'] as List?;
            final lastNurseId = staffChanges != null && staffChanges.isNotEmpty
                ? staffChanges.last['nurse']?.toString()
                : null;

            final filterNurseId = selectedNurseId ?? _currentUserId;

            return lastNurseId == filterNurseId;
          }).toList();

          // if (consultations.isEmpty && _selectedTabIndex == 0) {
          //   return const Center(
          //     child: Text(
          //       'No patients in queue.',
          //       style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          //     ),
          //   );
          // }
          final count = consultations.length;
          return Column(
            children: [
              // Nurse dropdown only on IP tab
              if (_selectedTabIndex == 1)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: _doctorDropdown(count),
                ),

              //const SizedBox(height: ),

              // Empty state OR list
              Expanded(
                child: consultations.isEmpty
                    ? Center(
                        child: Text(
                          'No patients in queue.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )
                    : _buildPatientList(consultations),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _doctorDropdown(int counts) {
    if (nurse.isEmpty) return const SizedBox();

    final uniqueNurses = {
      for (var n in nurse) n['user_Id']?.toString(): n,
    }.values.toList();

    final nurseIds = uniqueNurses.map((n) => n['user_Id']?.toString()).toList();

    final safeValue = nurseIds.contains(selectedNurseId)
        ? selectedNurseId
        : nurseIds.first;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        elevation: 6,
        shadowColor: Colors.black12,
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: safeValue,
              isExpanded: true,
              icon: const Icon(
                Icons.expand_more_rounded,
                size: 30,
                color: Colors.blueGrey,
              ),
              borderRadius: BorderRadius.circular(16),
              items: uniqueNurses.map((n) {
                final nurseName = n['name']?.toString() ?? 'Nurse';
                final nurseSpec = n['specialist']?.toString() ?? 'Specialist';
                final count = counts;
                final id = n['user_Id']?.toString();

                final isSelected = id == safeValue;

                return DropdownMenuItem<String>(
                  value: id,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue.shade50
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.blue.shade100,
                          child: const Icon(
                            Icons.medical_services_rounded,
                            color: Colors.blue,
                            size: 22,
                          ),
                        ),

                        const SizedBox(width: 14),

                        // Name & specialization
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                nurseName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              // const SizedBox(height: 3),
                              // Text(
                              //   nurseSpec,
                              //   style: TextStyle(
                              //     fontSize: 13,
                              //     color: Colors.grey.shade600,
                              //   ),
                              //   overflow: TextOverflow.ellipsis,
                              // ),
                            ],
                          ),
                        ),

                        //Count badge
                        // Container(
                        //   padding: const EdgeInsets.symmetric(
                        //     horizontal: 10,
                        //     vertical: 5,
                        //   ),
                        //   decoration: BoxDecoration(
                        //     color: Colors.green.shade50,
                        //     borderRadius: BorderRadius.circular(14),
                        //     border: Border.all(color: Colors.green.shade200),
                        //   ),
                        //   child: Text(
                        //     "$count",
                        //     style: TextStyle(
                        //       color: Colors.green.shade700,
                        //       fontWeight: FontWeight.w600,
                        //       fontSize: 13,
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => selectedNurseId = value);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientList(List<dynamic> consultations) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
              MaterialPageRoute(builder: (_) => InjectionPage(consultation: c)),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            _buildInfoRow(Icons.phone_outlined, "Cell", cell),
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

  Widget _buildTabButton(String label, int index) {
    bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black54,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
