import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Pages/NotificationsPage.dart';
import '../../../../utils/utils.dart';

class DoctorTestPage extends StatefulWidget {
  final String testName;
  final Map<String, dynamic> consultation;

  const DoctorTestPage({
    super.key,
    required this.testName,
    required this.consultation,
  });

  @override
  State<DoctorTestPage> createState() => _DoctorTestPageState();
}

class _DoctorTestPageState extends State<DoctorTestPage> {
  final TextEditingController _descriptionController = TextEditingController();
  final Set<String> selectedOptions = {};
  final Color primaryColor = const Color(0xFFBF955E);

  bool _isLoading = false;
  String? _dateTime;
  double totalAmount = 0.0;

  // ✅ Test list with base + option prices
  final Map<String, Map<String, dynamic>> testOptions = {
    'Blood Test': {
      'base': 200,
      'options': {
        'Hemoglobin': 50,
        'WBC Count': 60,
        'RBC Count': 60,
        'Platelet Count': 70,
      },
    },
    'CBC': {
      'base': 250,
      'options': {
        'Hemoglobin': 80,
        'Hematocrit': 100,
        'RBC': 90,
        'WBC': 90,
        'Platelets': 80,
      },
    },
    'Liver Function Test': {
      'base': 400,
      'options': {'ALT': 100, 'AST': 100, 'ALP': 120, 'Bilirubin': 80},
    },
    'Kidney Function Test': {
      'base': 350,
      'options': {
        'Creatinine': 80,
        'Urea': 70,
        'Uric Acid': 100,
        'Electrolytes': 120,
      },
    },
    'Cholesterol Test': {
      'base': 250,
      'options': {
        'Total Cholesterol': 100,
        'HDL': 80,
        'LDL': 90,
        'Triglycerides': 70,
      },
    },
    'Vitamin D': {
      'base': 300,
      'options': {'25(OH)D': 200},
    },
    'Vitamin B12': {
      'base': 300,
      'options': {'Serum B12': 180},
    },
    'HbA1C': {
      'base': 250,
      'options': {'Glycated Hemoglobin': 150},
    },
    'Urine Analysis': {
      'base': 200,
      'options': {'pH': 50, 'Protein': 70, 'Glucose': 60, 'RBC': 80, 'WBC': 80},
    },
    'Stool Test': {
      'base': 250,
      'options': {
        'Occult Blood': 100,
        'Parasites': 120,
        'Fat Content': 80,
        'Color': 50,
      },
    },
    'Serology Test': {
      'base': 400,
      'options': {
        'Hepatitis B': 250,
        'Hepatitis C': 300,
        'HIV': 200,
        'Syphilis': 180,
      },
    },
    'COVID-19 RT-PCR': {
      'base': 600,
      'options': {'Nasopharyngeal': 350, 'Oropharyngeal': 300},
    },
    'HIV Test': {
      'base': 350,
      'options': {'ELISA': 200, 'Rapid Test': 150, 'Western Blot': 400},
    },
    'Pregnancy Test': {
      'base': 200,
      'options': {'Urine Test': 120, 'Blood Test': 180},
    },
    'Hormone Test': {
      'base': 500,
      'options': {
        'Estrogen': 250,
        'Progesterone': 250,
        'Testosterone': 300,
        'FSH': 200,
        'LH': 200,
      },
    },
    'Tumor Marker Test': {
      'base': 800,
      'options': {
        'AFP': 400,
        'CEA': 450,
        'CA 125': 500,
        'CA 19-9': 500,
        'PSA': 350,
      },
    },
    'Lipid Profile': {
      'base': 500,
      'options': {
        'Total Cholesterol': 200,
        'HDL': 150,
        'LDL': 150,
        'Triglycerides': 180,
      },
    },
  };

  @override
  void initState() {
    super.initState();
    _updateTime();
    _calculateAmount();
  }

  void _updateTime() {
    setState(() {
      _dateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
    });
  }

  void _calculateAmount() {
    final testData = testOptions[widget.testName];
    double base = (testData?['base'] ?? 0).toDouble();
    double sum = base;

    if (testData != null && testData['options'] != null) {
      Map<String, dynamic> options = testData['options'];
      for (var opt in selectedOptions) {
        sum += (options[opt] ?? 0).toDouble();
      }
    }

    setState(() {
      totalAmount = double.parse(sum.toStringAsFixed(2));
    });
  }

  Future<void> _submitTestEntry() async {
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

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      final hospitalId = widget.consultation['hospital_Id'];
      final patientId = widget.consultation['patient_Id'];
      // final consultationId = widget.consultation['id'];
      final doctorId = prefs.getString('userId') ?? '';

      final data = {
        "hospital_Id": hospitalId,
        "patient_Id": patientId,
        "doctor_Id": doctorId,
        "staff_Id": [],
        "title": _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : widget.testName,
        "type": 'Tests',
        "scheduleDate": DateTime.now().toIso8601String(),
        "status": "PENDING",
        "paymentStatus": false,
        "result": '',
        "amount": totalAmount, // ✅ store as float
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
              content: Text('Test saved for ${widget.testName}'),
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
        throw Exception('Failed to save test: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving test: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final testData = testOptions[widget.testName];
    final options = testData?['options']?.keys.toList() ?? [];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    " ${widget.testName} ",
                    style: const TextStyle(
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_dateTime != null)
                    Text(
                      'Date: $_dateTime',
                      style: const TextStyle(color: Colors.grey),
                    ),

                  const SizedBox(height: 16),

                  _buildOptionContainer(options, testData),

                  const SizedBox(height: 20),

                  _buildDescriptionContainer(),

                  const SizedBox(height: 20),

                  // _buildAmountContainer(),

                  // const SizedBox(height: 30),
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton.icon(
                      onPressed: _submitTestEntry,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Test Entry'),
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
    );
  }

  Widget _buildOptionContainer(
    List<String> options,
    Map<String, dynamic>? testData,
  ) {
    // final prices = testData?['options'] ?? {};

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _containerDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Sub-Tests',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Divider(),
          if (options.isEmpty)
            const Text(
              'No specific sub-tests for this test type.',
              style: TextStyle(color: Colors.grey),
            )
          else
            ...options.map(
              (option) => CheckboxListTile(
                title: Text(option),
                value: selectedOptions.contains(option),
                onChanged: (selected) {
                  setState(() {
                    if (selected == true) {
                      selectedOptions.add(option);
                    } else {
                      selectedOptions.remove(option);
                    }
                    _calculateAmount();
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

  // Widget _buildAmountContainer() {
  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.all(16),
  //     decoration: _containerDecoration(),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         const Text(
  //           'Total Amount:',
  //           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
  //         ),
  //         Text(
  //           '₹ ${totalAmount.toStringAsFixed(2)}',
  //           style: const TextStyle(
  //             fontWeight: FontWeight.bold,
  //             fontSize: 18,
  //             color: Colors.green,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

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
