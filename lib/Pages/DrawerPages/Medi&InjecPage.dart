import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../Services/Medicine&Injection_service.dart';

const Color customGold = Color(0xFFBF955E);

class MediAndInjectionPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const MediAndInjectionPage({super.key, required this.data});

  @override
  State<MediAndInjectionPage> createState() => _MediAndInjectionPageState();
}

class _MediAndInjectionPageState extends State<MediAndInjectionPage> {
  final MedicineInjectionService _service = MedicineInjectionService();
  late Map<String, dynamic> item;

  @override
  void initState() {
    super.initState();
    item = Map<String, dynamic>.from(widget.data);
  }

  // Helper
  String _safeJoin(dynamic raw) {
    if (raw == null) return '-';
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        return _safeJoin(decoded);
      } catch (_) {
        return raw;
      }
    } else if (raw is List) {
      return raw.map((e) => e?.toString() ?? '').join(', ');
    } else if (raw is Map) {
      return raw.values.map((e) => e?.toString() ?? '').join(', ');
    } else {
      return raw.toString();
    }
  }

  Future<void> _toggleMedicineStatus() async {
    final id = item['id'];
    final newStatus = !(item['medicineStatus'] == true);
    try {
      final res = await _service.updateMedicineAndInjection(id, {
        'medicineStatus': newStatus,
      });
      if (res['status'] == 'success') {
        setState(() => item['medicineStatus'] = newStatus);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Medicine marked ${newStatus ? 'Given' : 'Pending'}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _toggleInjectionStatus() async {
    final id = item['id'];
    final newStatus = !(item['injectionStatus'] == true);
    try {
      final res = await _service.updateMedicineAndInjection(id, {
        'injectionStatus': newStatus,
      });
      if (res['status'] == 'success') {
        setState(() => item['injectionStatus'] = newStatus);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Injection marked ${newStatus ? 'Given' : 'Pending'}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _markComplete() async {
    final id = item['id'];
    try {
      final res = await _service.updateMedicineAndInjection(id, {
        'medicineStatus': true,
        'injectionStatus': true,
        'treatmentStatus': 'COMPLETED',
      });
      if (res['status'] == 'success') {
        setState(() {
          item['medicineStatus'] = true;
          item['injectionStatus'] = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Treatment marked as Completed ✅')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required Map<String, String> details,
    required bool status,
    required VoidCallback onToggle,
    bool isEmpty = false,
  }) {
    return Card(
      color: isEmpty ? Colors.grey.shade200 : Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isEmpty ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
                if (!isEmpty)
                  ElevatedButton.icon(
                    onPressed: onToggle,
                    icon: Icon(
                      status ? Icons.check_circle : Icons.pending_actions,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: Text(status ? 'Given' : 'Give'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: status ? Colors.green : customGold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (!isEmpty)
              ...details.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          '${e.key}:',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          e.value.isEmpty ? '-' : e.value,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patient = item['Patient'] ?? {};
    final patientName = patient['name'] ?? 'Unknown';
    final patientId = patient['user_Id'] ?? '-';
    final doctor = _safeJoin(item['doctor_Id']);
    final staff = _safeJoin(item['staff_Id']);
    final createdAt = item['createdAt'] ?? '';
    final formattedDate = createdAt.isNotEmpty
        ? DateFormat('dd MMM • hh:mm a').format(DateTime.parse(createdAt))
        : '-';

    final medicineStatus = (item['medicineStatus'] == true);
    final injectionStatus = (item['injectionStatus'] == true);

    final medicineData = <String, String>{
      'Names': _safeJoin(item['medicine_Id']).toString(),
      'Dosage': _safeJoin(item['dosageMedicine']).toString(),
      'Frequency': _safeJoin(item['frequencyMedicine']).toString(),
      'Duration': (item['durationMedicine'] ?? '-').toString(),
      'Notes': _safeJoin(item['medicineNotes']).toString(),
    };

    final injectionData = <String, String>{
      'Names': _safeJoin(item['injection_Id']).toString(),
      'Dosage': _safeJoin(item['dosageInjection']).toString(),
      'Frequency': _safeJoin(item['frequencyInjection']).toString(),
      'Duration': (item['durationInjection'] ?? '-').toString(),
      'Notes': _safeJoin(item['InjectionNotes']).toString(),
    };

    final hasMedicine = _safeJoin(item['medicine_Id']) != '-';
    final hasInjection = _safeJoin(item['injection_Id']) != '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine & Injection Details'),
        backgroundColor: customGold,
        elevation: 4,
      ),
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient header
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, color: customGold, size: 28),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$patientName (ID: $patientId)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.medical_information,
                          color: Colors.blueAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Doctor: $doctor',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.health_and_safety,
                          color: Colors.deepPurple,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Staff: $staff',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Created: $formattedDate',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Medicine Section
            _buildSection(
              title: 'Medicine Details',
              icon: Icons.medication,
              color: Colors.green,
              details: medicineData,
              status: medicineStatus,
              onToggle: _toggleMedicineStatus,
              isEmpty: !hasMedicine,
            ),

            // Injection Section
            _buildSection(
              title: 'Injection Details',
              icon: Icons.vaccines,
              color: Colors.indigo,
              details: injectionData,
              status: injectionStatus,
              onToggle: _toggleInjectionStatus,
              isEmpty: !hasInjection,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.done_all),
        label: const Text('Complete Treatment'),
        onPressed: _markComplete,
      ),
    );
  }
}
