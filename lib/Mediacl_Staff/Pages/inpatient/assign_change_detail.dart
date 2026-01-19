import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../../../../utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './addmission_history_detail.dart';

const Color royal = Color(0xFFBF955E);

class AdmittedPatientsPage extends StatefulWidget {
  const AdmittedPatientsPage({super.key});

  @override
  State<AdmittedPatientsPage> createState() => _AdmittedPatientsPageState();
}

class _AdmittedPatientsPageState extends State<AdmittedPatientsPage> {
  bool loading = true;
  List admissions = [];
  List filteredAdmissions = [];
  String search = "";
  String hospitalName = '';
  String hospitalPlace = '';
  String hospitalPhoto = '';
  String hospitalId = '';

  @override
  void initState() {
    super.initState();
    _loadHospitalInfo();
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

  Future<void> _loadHospitalInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('hospitalName');
    final place = prefs.getString('hospitalPlace');
    final photo = prefs.getString('hospitalPhoto');

    setState(() {
      hospitalName = name ?? "Unknown Hospital";
      hospitalPlace = place ?? "Unknown Place";
      hospitalPhoto =
          photo ??
          "https://as1.ftcdn.net/v2/jpg/02/50/38/52/1000_F_250385294_tdzxdr2Yzm5Z3J41fBYbgz4PaVc2kQmT.jpg";
    });
  }

  Widget _emptyState(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(
          color: royal,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Admitted Patients",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: royal,
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: royal))
          : Column(
              children: [
                /// 🔍 SEARCH BAR
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: filterList,
                    cursorColor: royal,
                    style: TextStyle(color: royal),
                    decoration: InputDecoration(
                      hintText: "Search patient, ward or bed",
                      hintStyle: TextStyle(color: royal),
                      prefixIcon: const Icon(Icons.search, color: royal),
                      prefixIconColor: royal,
                      filled: true,
                      fillColor: royal.withValues(alpha: 0.05),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: royal),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: royal, width: 2),
                      ),
                    ),
                  ),
                ),

                /// 📭 EMPTY STATES + LIST
                Expanded(
                  child: admissions.isEmpty
                      ? _emptyState("No admitted patients found")
                      : filteredAdmissions.isEmpty
                      ? _emptyState("No results for \"$search\"")
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredAdmissions.length,
                          itemBuilder: (_, i) {
                            final a = filteredAdmissions[i];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AdmissionDetailPage(admission: a),
                                  ),
                                );
                              },
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: const BorderSide(color: royal),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      /// Admission ID + Status
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Admission ID: ${a['id']}",
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: royal,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: royal.withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              a['status'],
                                              style: const TextStyle(
                                                color: royal,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 8),

                                      /// Patient Name
                                      Text(
                                        a['patient']['name'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: royal,
                                        ),
                                      ),

                                      const SizedBox(height: 6),

                                      /// Phone
                                      Text(
                                        "Phone: ${a['patient']['phone']['mobile']}",
                                        style: const TextStyle(fontSize: 14),
                                      ),

                                      const SizedBox(height: 6),

                                      /// Ward & Bed
                                      Text("Ward: ${a['bed']['ward']['name']}"),
                                      Text("Bed No: ${a['bed']['bedNo']}"),

                                      const SizedBox(height: 6),

                                      /// Admit Time
                                      Text(
                                        "Admitted On: ${DateTime.parse(a['admitTime']).toLocal()}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
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
