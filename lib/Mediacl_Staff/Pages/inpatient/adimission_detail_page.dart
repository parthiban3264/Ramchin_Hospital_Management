import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
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
  int? doctorId;
  int? nurseId;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final staffChange = (widget.admission['staffChange'] as List?) ?? [];
    final latest = staffChange.isNotEmpty ? staffChange.last : null;

    doctorId = latest != null
        ? int.tryParse(latest['doctor'].toString())
        : null;
    nurseId = latest != null ? int.tryParse(latest['nurse'].toString()) : null;
    loadBeds();
    loadStaff();
    _updateTime();
  }

  String? _dateTime;
  void _updateTime() {
    setState(() {
      _dateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
    });
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
    // final prefs = await SharedPreferences.getInstance();
    // final String userId = prefs.getString("userId") ?? "";

    final data = await AdminService().getMedicalStaff();

    final nurse = data
        .where((s) => s["role"].toString().toLowerCase() == "nurse")
        .toList();
    final doctors = data
        .where((s) => s["role"].toString().toLowerCase() == "doctor")
        .toList();

    setState(() {
      nurseList = nurse;
      doctorList = doctors;
      //filteredList = nonAdmins;
      isLoadingPage = false;
    });
  }

  // Future<void> saveChanges() async {
  //   if (!changeBed) return;
  //   final prefs = await SharedPreferences.getInstance();
  //   final hospitalId = prefs.getString('hospitalId');
  //   try {
  //     final response = await http.patch(
  //       Uri.parse(
  //         "$baseUrl/admissions/${widget.admission['id']}/$hospitalId/change-assignment",
  //       ),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode({
  //         if (changeBed && bedId != null && bedId != widget.admission['bedId'])
  //           'newBedId': bedId,
  //       }),
  //     );
  //
  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       // Success message
  //       if (!mounted) return;
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text("Assignment updated successfully"),
  //           backgroundColor: Colors.green,
  //         ),
  //       );
  //
  //       // Pop back and notify parent to refresh
  //       Navigator.pop(context, true);
  //     } else {
  //       // Show error
  //       if (!mounted) return;
  //       final error = jsonDecode(response.body);
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(
  //             "Failed to update: ${error['message'] ?? response.reasonPhrase}",
  //           ),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
  //     );
  //   }
  // }

  Future<void> saveChanges() async {
    setState(() => isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId');

    if (!changeBed && !changeDoctor && !changeNurse) return;

    try {
      // 🔹 1. Bed change
      if (changeBed && bedId != null && bedId != widget.admission['bedId']) {
        await http.patch(
          Uri.parse(
            "$baseUrl/admissions/${widget.admission['id']}/$hospitalId/change-assignment",
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'newBedId': bedId}),
        );
      }

      // 🔹 2. Doctor / Nurse change (staffChange)
      if (changeDoctor || changeNurse) {
        await http.patch(
          Uri.parse(
            "$baseUrl/admissions/${widget.admission['id']}/staff-change",
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode([
            {
              "doctor": doctorId.toString(),
              "nurse": nurseId.toString(),
              "dateTime": _dateTime.toString(),
            },
          ]),
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Changes saved successfully"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasAnyChange =
        (changeBed && bedId != widget.admission['bedId']) ||
        changeDoctor ||
        changeNurse;

    final a = widget.admission;
    // final consultationDoctorId = a['staffChange'][0]['doctor'].toString();
    // final consultationNurseId = a['staffChange'][0]['nurse'].toString();
    final List staffChange = (a['staffChange'] as List?) ?? [];

    final latestStaff = staffChange.isNotEmpty ? staffChange.last : null;

    final consultationDoctorId = latestStaff?['doctor']?.toString();

    final consultationNurseId = latestStaff?['nurse']?.toString();
    print('consultationDoctorId: $consultationDoctorId');
    print('doctorList: $doctorList');
    print('a: $a');
    final p = a['patient'];

    final admitTime = DateTime.parse(
      a['admitTime'],
    ).toLocal().toString().substring(0, 16);

    final bedText = "Bed ${a['bed']['bedNo']} • ${a['bed']['ward']['name']}";
    // final doctor = doctorList.firstWhere(
    //   (e) => e['user_Id'] == consultationDoctorId,
    //   orElse: () => null,
    // );
    // final nurse = nurseList.firstWhere(
    //   (e) => e['user_Id'] == consultationNurseId,
    //   orElse: () => null,
    // );
    final doctor = consultationDoctorId == null
        ? null
        : doctorList.firstWhere(
            (e) => e['user_Id'].toString() == consultationDoctorId,
            orElse: () => null,
          );

    final nurse = consultationNurseId == null
        ? null
        : nurseList.firstWhere(
            (e) => e['user_Id'].toString() == consultationNurseId,
            orElse: () => null,
          );

    // final doctorText = doctor != null
    //     ? '${doctor['name']} • ${doctor['specialist']}'
    //     : 'Unknown Doctor';
    // final nurseText = nurse != null ? '${nurse['name']}' : 'Unknown Doctor';
    final doctorText = doctor != null
        ? '${doctor['name']} • ${doctor['specialist']}'
        : 'Not assigned';

    final nurseText = nurse != null ? nurse['name'] : 'Not assigned';

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
            const SizedBox(height: 12),

            /// 💾 SAVE
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasAnyChange
                            ? Colors.orangeAccent
                            : Colors.grey,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: (hasAnyChange && !isSaving)
                          ? saveChanges
                          : null,
                      child: isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.save),
                                SizedBox(width: 8),
                                Text(
                                  "Save Changes",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
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
