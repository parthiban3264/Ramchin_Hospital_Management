import 'package:flutter/material.dart';

import '../../Services/treatment_service.dart';
import '../NotificationsPage.dart';

const Color primaryColor = Color(0xFFBF955E);

class TreatmentPage extends StatefulWidget {
  final Map<String, dynamic> treatment;

  const TreatmentPage({super.key, required this.treatment});

  @override
  State<TreatmentPage> createState() => _TreatmentPageState();
}

class _TreatmentPageState extends State<TreatmentPage> {
  final TreatmentService _treatmentService = TreatmentService();
  final TextEditingController _progressController = TextEditingController();

  late Map<String, dynamic> treatment;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    treatment = Map<String, dynamic>.from(widget.treatment);
    _progressController.text = treatment['progress'] ?? '0';
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ONGOING':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'SCHEDULED':
        return Colors.blueGrey;
      case 'COMPLETED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _statusText(String status) {
    switch (status.toUpperCase()) {
      case 'ONGOING':
        return 'Ongoing';
      case 'PENDING':
        return 'Pending';
      case 'SCHEDULED':
        return 'Scheduled';
      case 'COMPLETED':
        return 'Completed';
      default:
        return status;
    }
  }

  Future<void> _updateStatus() async {
    setState(() => _isUpdating = true);
    try {
      String newStatus = treatment['status'];
      String progressToSend = _progressController.text.trim();

      if ((int.tryParse(progressToSend) ?? 0) >= 100) {
        newStatus = 'COMPLETED';
        progressToSend = 'Finished';
      }

      final payload = {'status': newStatus, 'progress': progressToSend};

      final response = await _treatmentService.updateTreatment(
        treatment['id'],
        payload,
      );

      if (response['status'] == 'success') {
        setState(() {
          treatment['status'] = newStatus;
          treatment['progress'] = progressToSend;
          _progressController.text = newStatus == 'COMPLETED'
              ? '100'
              : _progressController.text;
        });

        if (newStatus == 'COMPLETED' && mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Treatment Completed"),
              content: const Text("✅ Treatment Completed Successfully!"),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, treatment);
                  },
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("✅ Progress updated successfully!")),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("⚠️ ${response['message']}")));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error updating status: $e")));
      }
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  void _startTreatmentConfirmation() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Start Treatment"),
        content: const Text(
          "Do you want to start this treatment? Progress will be set to 0 and status updated to Ongoing.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () {
              setState(() {
                treatment['status'] = 'ONGOING';
                treatment['progress'] = '0';
                _progressController.text = '0';
              });
              Navigator.pop(context);
            },
            child: const Text("Start"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patient = treatment['Patient'] as Map<String, dynamic>?;
    final doctor = treatment['Admin'] as Map<String, dynamic>?;

    final patientName = patient?['name'] ?? treatment['patient_Id'].toString();
    final patientId = treatment['patient_Id'] ?? '';
    final doctorName = doctor?['name'] ?? treatment['doctor_Id'].toString();
    final status = treatment['status'] ?? 'PENDING';
    final statusColor = _statusColor(status);

    final rawStaffId = treatment['staff_Id'];
    final rawTreatmentName = treatment['treatmentName'];

    // ✅ Convert list → string (remove [ ])
    final staffId = rawStaffId is List
        ? rawStaffId.join(', ')
        : rawStaffId?.toString() ?? '-';

    final treatmentName = rawTreatmentName is List
        ? rawTreatmentName.join(', ')
        : rawTreatmentName?.toString() ?? '-';

    final treatmentNotes = treatment['treatmentNotes']?['text'] ?? '-';
    final startDate = treatment['startDate'] ?? '-';
    final endDate = treatment['endDate'] ?? '-';
    final progress = treatment['progress'] ?? '0';

    final emailPersonal = patient?['email']?['personal'] ?? '-';
    // final emailGuardian = patient?['email']?['guardian'] ?? '-';
    final phoneMobile = patient?['phone']?['mobile'] ?? '-';
    // final phoneEmergency = patient?['phone']?['emergency'] ?? '-';
    final dob = patient?['dob'] != null
        ? patient!['dob'].toString().split('T')[0]
        : '-';
    final gender = patient?['gender'] ?? '-';
    final addressStreet = patient?['address']?['street'] ?? '-';
    final addressCity = patient?['address']?['city'] ?? '-';
    final addressZip = patient?['address']?['zip'] ?? '-';
    final bldGrp = patient?['bldGrp'] ?? '-';
    final bp = patient?['bp'] ?? '-';
    final sugar = patient?['sugar'] ?? '-';
    final height = patient?['height'] ?? '-';
    final weight = patient?['weight'] ?? '-';
    final medicalHistory = patient?['medicalHistory'] ?? '-';
    final currentProblem = patient?['currentProblem'] ?? '-';

    final bool isCompleted = status == 'COMPLETED';
    final bool isPending = status == 'PENDING';
    // final bool isOngoing = status == 'ONGOING';

    final String buttonText = isCompleted
        ? 'Completed'
        : (isPending ? 'Start Treatment' : 'Update Progress');
    final Color buttonColor = isCompleted
        ? Colors.grey
        : (isPending ? primaryColor : Colors.green);

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
                    'Treatment',
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
      body: _isUpdating
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Profile Card
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: primaryColor.withValues(
                              alpha: 0.2,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Patient: $patientName",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text("Patient ID: $patientId"),
                                const SizedBox(height: 4),
                                Text("Doctor: $doctorName"),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _statusText(status),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Treatment Info Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Staff ID: $staffId"),
                          const SizedBox(height: 4),
                          Text("Treatment: $treatmentName"),
                          const SizedBox(height: 4),
                          Text("Notes: $treatmentNotes"),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text("Start: $startDate"),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.event_available,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text("End: $endDate"),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.timeline, color: primaryColor),
                              const SizedBox(width: 8),
                              Text("Progress: $progress"),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Patient Details Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Contact & Personal Info
                          Row(
                            children: [
                              const Icon(Icons.phone, color: primaryColor),
                              const SizedBox(width: 8),
                              Expanded(child: Text("Mobile: $phoneMobile")),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.email, color: primaryColor),
                              const SizedBox(width: 8),
                              Expanded(child: Text("Email: $emailPersonal")),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.person, color: primaryColor),
                              const SizedBox(width: 8),
                              Text("Gender: $gender"),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.cake, color: primaryColor),
                              const SizedBox(width: 8),
                              Text("DOB: $dob"),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Address: $addressStreet, $addressCity, $addressZip",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Medical Info
                          Row(
                            children: [
                              const Icon(Icons.favorite, color: primaryColor),
                              const SizedBox(width: 8),
                              Text("BP: $bp  |  Sugar: $sugar"),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.height, color: primaryColor),
                              const SizedBox(width: 8),
                              Text("Height: $height cm  |  Weight: $weight kg"),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.bloodtype, color: primaryColor),
                              const SizedBox(width: 8),
                              Text("Blood Group: $bldGrp"),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.medical_services,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text("Current Problem: $currentProblem"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.history_edu,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text("Medical History: $medicalHistory"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 4. Action Card (Progress input + Elevator button)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                            controller: _progressController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Progress (%)",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            enabled: !isPending && !isCompleted,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: isCompleted
                                ? null
                                : () {
                                    if (isPending) {
                                      _startTreatmentConfirmation();
                                    } else {
                                      _updateStatus();
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonColor,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              buttonText,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (isCompleted) const SizedBox(height: 16),
                  if (isCompleted)
                    Center(
                      child: Text(
                        "✅ Treatment Completed",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
