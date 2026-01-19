import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../../../../utils/utils.dart';
import 'addmission_history_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color royal = Color(0xFFBF955E);

class WardsAndBedsPage extends StatefulWidget {
  const WardsAndBedsPage({super.key});

  @override
  State<WardsAndBedsPage> createState() => _WardsAndBedsPageState();
}

class _WardsAndBedsPageState extends State<WardsAndBedsPage> {
  bool loading = true;
  List wards = [];
  List filteredWards = [];
  String search = "";
  String hospitalName = '';
  String hospitalPlace = '';
  String hospitalPhoto = '';

  @override
  void initState() {
    super.initState();
    _loadHospitalInfo();
    fetchWards();
  }

  Widget _emptyState(String msg) {
    return Center(
      child: Text(
        msg,
        style: const TextStyle(
          color: royal,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _loadHospitalInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hospitalName = prefs.getString('hospitalName') ?? 'Unknown Hospital';
      hospitalPlace = prefs.getString('hospitalPlace') ?? 'Unknown Place';
      hospitalPhoto =
          prefs.getString('hospitalPhoto') ??
          "https://as1.ftcdn.net/v2/jpg/02/50/38/52/1000_F_250385294_tdzxdr2Yzm5Z3J41fBYbgz4PaVc2kQmT.jpg";
    });
  }

  Future<void> fetchWards() async {
    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId');
    final res = await http.get(
      Uri.parse('$baseUrl/wards/hospital/patient/$hospitalId'),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      // Keep only beds that have patients
      for (var ward in data) {
        ward['beds'] = (ward['beds'] as List)
            .where((bed) => (bed['admissions'] as List).isNotEmpty)
            .toList();
      }

      // Keep only wards with at least one bed with patients
      final filtered = data
          .where((ward) => (ward['beds'] as List).isNotEmpty)
          .toList();

      setState(() {
        wards = filtered;
        filteredWards = filtered;
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  void filterWards(String query) {
    final q = query.toLowerCase();
    setState(() {
      search = query;
      filteredWards = wards.where((ward) {
        final wardName = ward['name'].toString().toLowerCase();
        return wardName.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Wards & Beds",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: royal,
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: royal))
          : wards.isEmpty
          ? _emptyState("No patients currently admitted")
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Hospital info
                  buildHospitalCard(
                    hospitalName: hospitalName,
                    hospitalPlace: hospitalPlace,
                    hospitalPhoto: hospitalPhoto,
                  ),
                  const SizedBox(height: 18),

                  // Search bar
                  TextField(
                    onChanged: filterWards,
                    cursorColor: royal,
                    style: TextStyle(color: royal),
                    decoration: InputDecoration(
                      hintText: "Search ward",
                      hintStyle: TextStyle(color: royal),
                      prefixIcon: const Icon(Icons.search, color: royal),
                      filled: true,
                      fillColor: royal.withOpacity(0.05),
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
                  const SizedBox(height: 18),

                  // List of filtered wards
                  ...filteredWards.map<Widget>((ward) {
                    final beds = ward['beds'] as List;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Stack(
                        children: [
                          // ===== MAIN WARD CARD =====
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 18,
                            ), // space for header overlap
                            child: Card(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: royal),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  24,
                                  14,
                                  14,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ===== NESTED PATIENT CARDS =====
                                    ...beds.expand<Widget>((bed) {
                                      final admissions =
                                          bed['admissions'] as List;

                                      return admissions.map<Widget>((
                                        admission,
                                      ) {
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    AdmissionDetailPage(
                                                      admission: admission,
                                                    ),
                                              ),
                                            );
                                          },
                                          child: Card(
                                            color: Colors.white,
                                            elevation: 0,
                                            margin: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              side: BorderSide(
                                                color: royal.withOpacity(0.4),
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(14),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Bed No: ${bed['bedNo']}",
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: royal,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    admission['patient']['name'],
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: royal,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    "Doctor: ${admission['doctor']['name']}",
                                                  ),
                                                  Text(
                                                    "Nurse: ${admission['nurse']['name']}",
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Align(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 5,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: royal
                                                            .withOpacity(0.15),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              20,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        admission['status'],
                                                        style: const TextStyle(
                                                          color: royal,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList();
                                    }).toList(),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // ===== STACK HEADER (OVERLAY) =====
                          // ===== STACK HEADER (ALWAYS CENTERED) =====
                          Positioned.fill(
                            top: 0,
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: royal,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  "${ward['name']} • ${ward['type']}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
    );
  }
}

Widget buildHospitalCard({
  required String hospitalName,
  required String hospitalPlace,
  required String hospitalPhoto,
}) {
  return Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFEDBA77), Color(0xFFC59A62)],
        begin: Alignment.topLeft,
        end: Alignment.bottomLeft,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 5)),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(18.0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Image.network(
              hospitalPhoto,
              height: 65,
              width: 65,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.local_hospital,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hospitalName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hospitalPlace,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
