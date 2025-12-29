import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Pages/NotificationsPage.dart';
import '../../../../utils/utils.dart';

class DoctorScanPage extends StatefulWidget {
  final Map<String, dynamic> consultation;
  final String scanName;

  const DoctorScanPage({
    super.key,
    required this.scanName,
    required this.consultation,
  });

  @override
  State<DoctorScanPage> createState() => _DoctorScanPageState();
}

class _DoctorScanPageState extends State<DoctorScanPage> {
  final TextEditingController _descriptionController = TextEditingController();
  final Set<String> selectedOptions = {};
  final Color primaryColor = const Color(0xFFBF955E);

  bool _isLoading = false;
  String? _dateTime;

  // ✅ Scan pricing (base + per-option)
  final Map<String, Map<String, dynamic>> scanPricing = {
    'CT-Scan': {
      'base': 500,
      'options': {
        'Brain': 300,
        'Chest': 200,
        'Abdomen': 300,
        'Pelvis': 100,
        'Spine': 400,
        'Neck': 250,
        'Extremities': 200,
      },
    },
    'X-Ray': {
      'base': 300,
      'options': {
        'Skull (AP/Lateral View)': 150,
        'Chest (PA/Lateral View)': 120,
        'Abdomen (AP View)': 100,
        'Pelvis': 100,
        'Spine (Cervical/Thoracic/Lumbar)': 200,
        'Upper Limb (Shoulder/Arm/Wrist)': 100,
        'Lower Limb (Hip/Knee/Ankle/Foot)': 100,
      },
    },
    'MRI-Scan': {
      'base': 700,
      'options': {
        'Brain': 400,
        'Spine (Cervical/Thoracic/Lumbar)': 350,
        'Joints (Knee/Shoulder/Ankle)': 300,
        'Abdomen': 200,
        'Pelvis': 200,
      },
    },
    'Ultrasound': {
      'base': 400,
      'options': {
        'Abdomen': 150,
        'Pelvis': 120,
        'Thyroid': 100,
        'Breast': 150,
        'Kidneys': 120,
        'Obstetric': 150,
        'Soft Tissue': 100,
      },
    },
    'PET-Scan': {
      'base': 1000,
      'options': {
        'Whole Body': 800,
        'Brain': 600,
        'Lungs': 500,
        'Abdomen': 400,
        'Bone Metastasis': 700,
      },
    },
    'EEG': {
      'base': 300,
      'options': {
        'Brain Activity (Standard)': 200,
        'Sleep EEG': 100,
        'Ambulatory EEG': 200,
      },
    },
    'Bone Scan': {
      'base': 700,
      'options': {
        'Skull': 400,
        'Spine': 500,
        'Pelvis': 300,
        'Ribs': 600,
        'Upper Limbs': 200,
        'Lower Limbs': 200,
      },
    },
  };

  @override
  void initState() {
    super.initState();
    _updateTime();
  }

  void _updateTime() {
    setState(() {
      _dateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
    });
  }

  Future<void> _refreshPage() async {
    setState(() {
      selectedOptions.clear();
      _descriptionController.clear();
      _updateTime();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Page refreshed')));
  }

  int _calculateTotalAmount() {
    final scan = scanPricing[widget.scanName];
    if (scan == null) return 0;

    final base = scan['base'] ?? 0;
    final options = scan['options'] as Map<String, int>;
    int total = base;
    for (var opt in selectedOptions) {
      total += options[opt] ?? 0;
    }
    return total;
  }

  Future<void> _submitScanEntry() async {
    if (selectedOptions.isEmpty && _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select at least one option or enter a description.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final hospitalId = widget.consultation['hospital_Id'];
      final patientId = widget.consultation['patient_Id'];
      // final consultationId = widget.consultation['id'];
      final prefs = await SharedPreferences.getInstance();

      final doctorId = prefs.getString('userId') ?? '';

      final totalAmount = _calculateTotalAmount();

      final data = {
        "hospital_Id": hospitalId,
        "patient_Id": patientId,
        "doctor_Id": doctorId,
        "staff_Id": [],
        "title": _descriptionController.text.trim(),
        "type": widget.scanName,
        "scheduleDate": DateTime.now().toIso8601String(),
        "status": "PENDING",
        "paymentStatus": false,
        "result": '',
        "amount": totalAmount,
        "selectedOptions": selectedOptions.toList(),
        "createdAt": _dateTime.toString(),
      };

      // if (consultationId != null) {
      //   await ConsultationService().updateConsultation(consultationId, {
      //     'status': 'ONGOING',
      //     'updatedAt': _dateTime.toString(),
      //   });
      // }

      final response = await http.post(
        Uri.parse('$baseUrl/testing_and_scanning_patient/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Scan saved for ${widget.scanName}'),
              backgroundColor: Colors.green.shade600,
            ),
          );
          Navigator.pop(context, true);
        }

        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (_) => const DrOutPatientQueuePage()),
        // );
      } else {
        throw Exception('Failed to save scan: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving scan: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scan = scanPricing[widget.scanName];
    final options = (scan?['options'] as Map<String, int>?) ?? {};

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: primaryColor,
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
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    widget.scanName,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshPage,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_dateTime != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Date: $_dateTime',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),

                    _buildOptionContainer(scan, options),
                    const SizedBox(height: 20),
                    _buildDescriptionContainer(),
                    const SizedBox(height: 20),

                    // ✅ Submit button
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton.icon(
                        onPressed: _submitScanEntry,
                        icon: const Icon(Icons.save),
                        label: const Text('Save Scan Entry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOptionContainer(
    Map<String, dynamic>? scan,
    Map<String, int> options,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _containerDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Body Parts / Views',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Divider(),
          if (options.isEmpty)
            const Text(
              'No specific options for this scan type.',
              style: TextStyle(color: Colors.grey),
            )
          else
            ...options.entries.map(
              (entry) => CheckboxListTile(
                title: Text(entry.key),
                value: selectedOptions.contains(entry.key),
                onChanged: (selected) {
                  setState(() {
                    if (selected == true) {
                      selectedOptions.add(entry.key);
                    } else {
                      selectedOptions.remove(entry.key);
                    }
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDescriptionContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _containerDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description / Findings',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descriptionController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Enter findings or observations...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _containerDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
      ],
    );
  }
}
