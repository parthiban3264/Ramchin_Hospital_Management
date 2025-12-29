import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../Admin/Colors/Colors.dart';
import '../../Services/Medicine&Injection_service.dart';
import '../NotificationsPage.dart';
import 'Medi&InjecPage.dart';

const Color customGold = Color(0xFFBF955E);

class MedicineQueuePage extends StatefulWidget {
  const MedicineQueuePage({Key? key}) : super(key: key);

  @override
  State<MedicineQueuePage> createState() => _MedicineQueuePageState();
}

class _MedicineQueuePageState extends State<MedicineQueuePage> {
  final MedicineInjectionService _service = MedicineInjectionService();
  late Future<List<dynamic>> _futureList;

  @override
  void initState() {
    super.initState();
    _futureList = _service.getAllMedicineAndInjection();
  }

  Future<void> _refresh() async {
    setState(() {
      _futureList = _service.getAllMedicineAndInjection();
    });
  }

  // ✅ Utility: Clean decode for lists/maps/strings
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

  // ✅ Filter PENDING and ONGOING
  List<Map<String, dynamic>> _filterActive(List<dynamic> data) {
    return data
        .where(
          (e) =>
              (e['status']?.toString().toUpperCase() == 'PENDING' ||
              e['status']?.toString().toUpperCase() == 'ONGOING'),
        )
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> _updateStatusToOngoing(int id) async {
    try {
      final payload = {'status': 'ONGOING'};
      final res = await _service.updateMedicineAndInjection(id, payload);
      if (res['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated to ONGOING')),
        );
        await _refresh();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: ${res['message']}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final patient = item['Patient'] ?? {};
    final patientName = patient['name'] ?? 'Unknown';
    final patientId = patient['user_Id'] ?? '-';

    final doctor = _safeJoin(item['doctor_Id']);
    final staff = _safeJoin(item['staff_Id']);
    final status = item['status']?.toString().toUpperCase() ?? '-';
    final createdAt = item['createdAt'] ?? '';
    final formattedDate = createdAt.isNotEmpty
        ? DateFormat('dd MMM • hh:mm a').format(DateTime.parse(createdAt))
        : '-';

    final medicineStatus = (item['medicineStatus'] == true);
    final injectionStatus = (item['injectionStatus'] == true);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          if (status == 'PENDING') {
            await _updateStatusToOngoing(item['id']);
          } else if (status == 'ONGOING') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MediAndInjectionPage(data: item),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Patient + Status
              Row(
                children: [
                  const Icon(Icons.person, color: customGold, size: 26),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "$patientName  (ID: $patientId)",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: status == 'PENDING'
                          ? Colors.orange.withOpacity(0.2)
                          : Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: status == 'PENDING'
                            ? Colors.orange
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Row 2: Doctor
              Row(
                children: [
                  const Icon(
                    Icons.medical_information,
                    color: Colors.blueAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Doctor: $doctor",
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Row 3: Staff
              Row(
                children: [
                  const Icon(
                    Icons.health_and_safety,
                    color: Colors.deepPurple,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Staff: $staff",
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(thickness: 0.8),

              // Row 4: Medicine / Injection icons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.medication,
                        color: medicineStatus
                            ? Colors.green
                            : Colors.grey.shade400,
                        size: 24,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Medicine",
                        style: TextStyle(
                          color: medicineStatus
                              ? Colors.green
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.vaccines,
                        color: injectionStatus
                            ? Colors.green
                            : Colors.grey.shade400,
                        size: 24,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Injection",
                        style: TextStyle(
                          color: injectionStatus
                              ? Colors.green
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  formattedDate,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
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
          decoration: const BoxDecoration(
            color: CustomColors.customGold,
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
                    'Medical Procedures',
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
      backgroundColor: Colors.grey.shade100,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: customGold,
        child: FutureBuilder<List<dynamic>>(
          future: _futureList,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No data found'));
            }

            final filtered = _filterActive(snapshot.data!);
            if (filtered.isEmpty) {
              return const Center(child: Text('No pending or ongoing records'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: filtered.length,
              itemBuilder: (context, i) => _buildCard(filtered[i]),
            );
          },
        ),
      ),
    );
  }
}
