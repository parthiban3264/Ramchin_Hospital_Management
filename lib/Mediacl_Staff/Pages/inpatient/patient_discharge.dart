import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Admin/Pages/admin_edit_profile_page.dart';
import '../../../Pages/NotificationsPage.dart';
import '../../../Services/charge_Service.dart';
import '../../../utils/utils.dart';

class PatientDischargePage extends StatefulWidget {
  const PatientDischargePage({super.key});

  @override
  State<PatientDischargePage> createState() => _PatientDischargePageState();
}

class _PatientDischargePageState extends State<PatientDischargePage> {
  bool loading = true;
  List admissions = [];
  List filteredAdmissions = [];
  String search = "";
  final Color royal = primaryColor;

  @override
  void initState() {
    super.initState();
    fetchAdmissions();
  }

  Future<void> fetchAdmissions() async {
    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId');

    final res = await http.get(
      Uri.parse("$baseUrl/admissions/$hospitalId/admitted"),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        admissions = data;
        filteredAdmissions = data;
        loading = false;
      });
    }
  }

  void filterList(String query) {
    final q = query.toLowerCase();

    setState(() {
      search = query;
      filteredAdmissions = admissions.where((a) {
        final patient = a['patient']['name'].toString().toLowerCase();
        final ward = a['bed']['ward']['name'].toString().toLowerCase();
        final bed = a['bed']['bedNo'].toString();
        return patient.contains(q) || ward.contains(q) || bed.contains(q);
      }).toList();
    });
  }

  Future<void> dischargePatient(int id) async {
    final success = await ChargeService.dischargeAdmission(id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Patient discharged successfully' : 'Discharge failed',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) fetchAdmissions();
  }

  Widget _emptyState(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ),
      ),
    );
  }

  String formatDate(String iso) {
    final d = DateTime.parse(iso).toLocal();
    return "${d.day}/${d.month}/${d.year} • ${d.hour}:${d.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

                  const Text(
                    "Patient Discharge",
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
      body: loading
          ? Center(child: CircularProgressIndicator(color: royal))
          : Column(
              children: [
                /// 🔍 SEARCH
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: filterList,
                    decoration: InputDecoration(
                      hintText: "Search patient, ward or bed",
                      prefixIcon: Icon(Icons.search, color: royal),
                      filled: true,
                      fillColor: royal.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: royal),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: royal, width: 2),
                      ),
                    ),
                  ),
                ),

                /// 📋 LIST
                Expanded(
                  child: admissions.isEmpty
                      ? _emptyState("No admitted patients")
                      : filteredAdmissions.isEmpty
                      ? _emptyState("No results for \"$search\"")
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredAdmissions.length,
                          itemBuilder: (_, i) {
                            final a = filteredAdmissions[i];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    /// Header
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Admission #${a['id']}",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: royal,
                                          ),
                                        ),
                                        Chip(
                                          label: Text(a['status']),
                                          backgroundColor: royal.withOpacity(
                                            0.15,
                                          ),
                                          labelStyle: TextStyle(
                                            color: royal,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 10),

                                    /// Patient
                                    Text(
                                      a['patient']['name'],
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    Row(
                                      children: [
                                        const Icon(Icons.phone, size: 16),
                                        const SizedBox(width: 6),
                                        Text(a['patient']['phone']['mobile']),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.local_hospital,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "${a['bed']['ward']['name']} • Bed ${a['bed']['bedNo']}",
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    Text(
                                      "Admitted: ${formatDate(a['admitTime'])}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),

                                    const SizedBox(height: 14),

                                    /// DISCHARGE BUTTON
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        icon: const Icon(
                                          Icons.logout,
                                          color: Colors.white,
                                        ),
                                        label: const Text(
                                          "Discharge",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red.shade600,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text(
                                                "Confirm Discharge",
                                              ),
                                              content: const Text(
                                                "Are you sure you want to discharge this patient?",
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text(
                                                    "Cancel",
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.redAccent,
                                                      ),
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    dischargePatient(a['id']);
                                                  },
                                                  child: const Text(
                                                    "Discharge",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
