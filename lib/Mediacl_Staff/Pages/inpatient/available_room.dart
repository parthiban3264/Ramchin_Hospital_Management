import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../../../../utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color royal = Color(0xFFBF955E);

class AvailableRoomsPage extends StatefulWidget {
  const AvailableRoomsPage({super.key});

  @override
  State<AvailableRoomsPage> createState() => _AvailableRoomsPageState();
}

class _AvailableRoomsPageState extends State<AvailableRoomsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> wards = [];
  List<Map<String, dynamic>> filteredWards = [];
  String searchQuery = "";
  String hospitalName = '';
  String hospitalPlace = '';
  String hospitalPhoto = '';
  String hospitalId = '';

  @override
  void initState() {
    super.initState();
    _loadHospitalInfo();
    fetchAvailableBeds();
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

  Future<void> fetchAvailableBeds() async {
    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId');
    final res = await http.get(Uri.parse("$baseUrl/wards/all/$hospitalId"));

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = List<Map<String, dynamic>>.from(jsonDecode(res.body));

      // Keep all beds
      setState(() {
        wards = data;
        filteredWards = data;
        _loading = false;
      });
    }
  }

  void _filterWards(String query) {
    final lowerQuery = query.toLowerCase();

    final filtered = wards.where((ward) {
      final name = (ward["name"] as String).toLowerCase();
      final type = (ward["type"] as String).toLowerCase();
      return name.contains(lowerQuery) || type.contains(lowerQuery);
    }).toList();

    setState(() {
      searchQuery = query;
      filteredWards = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: royal,
        title: const Text(
          "Available Rooms",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: royal))
          : Column(
              children: [
                buildHospitalCard(
                  hospitalName: hospitalName,
                  hospitalPlace: hospitalPlace,
                  hospitalPhoto: hospitalPhoto,
                ),
                const SizedBox(height: 18),

                /// SEARCH BAR
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    onChanged: _filterWards,
                    cursorColor: royal,
                    style: TextStyle(color: royal),
                    decoration: InputDecoration(
                      hintText: "Search by ward name or type",
                      hintStyle: TextStyle(color: royal),
                      prefixIcon: const Icon(Icons.search, color: royal),
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

                /// WARD LIST
                Expanded(
                  child: filteredWards.isEmpty
                      ? const Center(
                          child: Text(
                            "No rooms available",
                            style: TextStyle(color: royal, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredWards.length,
                          itemBuilder: (context, index) {
                            final ward = filteredWards[index];
                            return _wardCard(ward);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _wardCard(Map<String, dynamic> ward) {
    final beds = ward["beds"] as List;

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: royal, width: 1.5),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// WARD HEADER
            Text(
              ward["name"],
              style: const TextStyle(
                color: royal,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text("Type: ${ward["type"]}", style: const TextStyle(color: royal)),

            const SizedBox(height: 12),

            /// ALL BEDS WITH STATUS COLOR
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: beds.map<Widget>((bed) {
                final isAvailable = bed["status"] == "AVAILABLE";

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isAvailable ? Colors.green : Colors.red,
                    ),
                    color: (isAvailable
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1)),
                  ),
                  child: Text(
                    "Bed ${bed["bedNo"]}",
                    style: TextStyle(
                      color: isAvailable
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
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
