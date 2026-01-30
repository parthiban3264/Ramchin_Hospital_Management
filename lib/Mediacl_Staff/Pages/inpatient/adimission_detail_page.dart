import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../../../utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Services/admin_service.dart';
import '../../../Services/charge_Service.dart';

const Color royal = Color(0xFFBF955E);

class AdmissionDetailPage extends StatefulWidget {
  final Map admission;
  const AdmissionDetailPage({super.key, required this.admission});

  @override
  State<AdmissionDetailPage> createState() => _AdmissionDetailPageState();
}

class _AdmissionDetailPageState extends State<AdmissionDetailPage> {
  int? bedId;
  bool changeBed = false;
  bool changeDoctor = false;
  bool changeNurse = false;
  List<dynamic> nurseList = [];
  List<dynamic> doctorList = [];
  bool isLoadingPage = true;
  List beds = [];
  int? doctorId = 123;
  int? nurseId = 1234567895;

  @override
  void initState() {
    super.initState();
    loadBeds();
    loadStaff();
  }

  Future<void> loadBeds() async {
    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId');
    final res = await http.get(Uri.parse("$baseUrl/wards/all/$hospitalId"));
    final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;

    final List<Map<String, dynamic>> allBeds = [];

    for (final ward in data) {
      final List<dynamic> wardBeds = ward['beds'] ?? [];

      for (final bed in wardBeds) {
        allBeds.add({...bed, 'ward': ward});
      }
    }

    final availableBeds = allBeds
        .where((b) => b['status'] == 'AVAILABLE')
        .toList();

    final currentBed = allBeds.firstWhere(
      (b) => b['id'] == widget.admission['bedId'],
      orElse: () => {},
    );

    if (currentBed.isNotEmpty &&
        !availableBeds.any((b) => b['id'] == currentBed['id'])) {
      availableBeds.insert(0, currentBed);
    }

    setState(() {
      beds = availableBeds;
      bedId ??= widget.admission['bedId'];
    });
  }

  void loadStaff() async {
    setState(() => isLoadingPage = true);
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("userId") ?? "";

    final data = await AdminService().getMedicalStaff();

    final nurse = data
        .where((s) => s["role"].toString().toLowerCase() == "nurse")
        .toList();
    final doctors = data
        .where((s) => s["role"].toString().toLowerCase() == "doctor")
        .toList();
    print('nurse $nurse');
    print('doctor $doctors');
    setState(() {
      nurseList = nurse;
      doctorList = doctors;
      //filteredList = nonAdmins;
      isLoadingPage = false;
    });
  }

  Future<void> saveChanges() async {
    if (!changeBed) return;
    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId');
    try {
      final response = await http.patch(
        Uri.parse(
          "$baseUrl/admissions/${widget.admission['id']}/$hospitalId/change-assignment",
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (changeBed && bedId != null && bedId != widget.admission['bedId'])
            'newBedId': bedId,
        }),
      );

      if (response.statusCode == 200) {
        // Success message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Assignment updated successfully"),
            backgroundColor: Colors.green,
          ),
        );

        // Pop back and notify parent to refresh
        Navigator.pop(context, true);
      } else {
        // Show error
        if (!mounted) return;
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to update: ${error['message'] ?? response.reasonPhrase}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> dischargePatient() async {
    final success = await ChargeService.dischargeAdmission(
      widget.admission['id'],
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient discharged successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true); // refresh previous screen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Discharge failed'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.admission;
    final p = a['patient'];

    final admitTime = DateTime.parse(
      a['admitTime'],
    ).toLocal().toString().substring(0, 16);

    final bedText = "Bed ${a['bed']['bedNo']} • ${a['bed']['ward']['name']}";
    final doctorText = "1";
    final nurseText = "2";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: royal,
        title: const Text(
          "Admission Details",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🆔 ADMISSION CARD
            _infoCard(
              title: "Admission Info",
              children: [
                _row("Admission ID", a['id'].toString()),
                _row("Status", a['status']),
                _row("Admitted On", admitTime),
              ],
            ),

            const SizedBox(height: 16),

            /// 👤 PATIENT CARD
            _infoCard(
              title: "Patient",
              children: [
                _row("Name", p['name']),
                _row("Mobile", p['phone']['mobile']),
              ],
            ),

            const SizedBox(height: 16),

            if (beds.isNotEmpty)
              _editableCard(
                title: "Bed",
                value: bedText,
                changing: changeBed,
                onTap: () => setState(() => changeBed = !changeBed),
                child: DropdownButtonFormField<int>(
                  key: ValueKey(beds.length), // 🔥 FORCE REBUILD
                  value: changeBed ? bedId : null,
                  hint: const Text("Select Bed"),
                  items: beds.map<DropdownMenuItem<int>>((b) {
                    return DropdownMenuItem(
                      value: b['id'],
                      child: Text("Bed ${b['bedNo']} • ${b['ward']['name']}"),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => bedId = v),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ),

            _editableCard(
              title: "Doctor",
              value: doctorText,
              changing: changeDoctor,
              onTap: () => setState(() => changeDoctor = !changeDoctor),
              child: DropdownButtonFormField<int>(
                key: ValueKey(doctorList.length), // 🔥 FORCE REBUILD
                value: changeDoctor ? doctorId : null,
                hint: const Text("Select Doctor"),
                items: doctorList.map<DropdownMenuItem<int>>((b) {
                  return DropdownMenuItem(
                    value: int.parse(b['user_Id']),
                    child: Text("${b['name']} • ${b['specialist']}"),
                  );
                }).toList(),
                onChanged: (v) => setState(() => doctorId = v),
              ),
            ),

            _editableCard(
              title: "Nurses",
              value: nurseText,
              changing: changeNurse,
              onTap: () => setState(() => changeNurse = !changeNurse),
              child: DropdownButtonFormField<int>(
                key: ValueKey(nurseList.length), // 🔥 FORCE REBUILD
                value: changeNurse ? nurseId : null,
                hint: const Text("Select Nurse"),
                items: nurseList.map<DropdownMenuItem<int>>((b) {
                  return DropdownMenuItem(
                    value: int.parse(b['user_Id'].toString()),
                    child: Text(b['name'].toString()),
                  );
                }).toList(),
                onChanged: (v) => setState(() => nurseId = v),
              ),
            ),
            const SizedBox(height: 10),

            /// 💾 SAVE
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text(
                        "Save Changes",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: saveChanges,
                    ),
                  ),
                ),
                //const SizedBox(width: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({required String title, required List<Widget> children}) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: royal),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: royal,
              ),
            ),
            const Divider(color: royal),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _editableCard({
    required String title,
    required String value,
    required bool changing,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: royal),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: royal,
                  ),
                ),
                TextButton(
                  onPressed: onTap,
                  child: Text(
                    changing ? "Cancel" : "Change",
                    style: TextStyle(color: royal),
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            if (changing) ...[const SizedBox(height: 12), child],
          ],
        ),
      ),
    );
  }

  // Widget _dropdown({
  //   required String hint,
  //   required List items,
  //   required int? value,
  //   required Function(int?) onChanged,
  // }) {
  //   return DropdownButtonFormField<int>(
  //     value: value,
  //     hint: Text(hint),
  //     items: items
  //         .map<DropdownMenuItem<int>>(
  //           (i) => DropdownMenuItem(value: i['id'], child: Text(i['name'])),
  //         )
  //         .toList(),
  //     onChanged: onChanged,
  //   );
  // }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
