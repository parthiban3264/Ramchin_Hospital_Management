import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../../../utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const Color royal = Color(0xFFBF955E);

class AdmitPatientPage extends StatefulWidget {
  const AdmitPatientPage({super.key});

  @override
  State<AdmitPatientPage> createState() => _AdmitPatientPageState();
}

class _AdmitPatientPageState extends State<AdmitPatientPage> {
  final _formKey = GlobalKey<FormState>();
  final phoneCtrl = TextEditingController();
  List patientsFound = [];
  int? selectedPatientId;
  final nameCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  String? gender;
  final admitByNameCtrl = TextEditingController();
  final admitByPhoneCtrl = TextEditingController();
  final reasonCtrl = TextEditingController();
  final admitByRelationCtrl = TextEditingController();
  List doctors = [];
  List nurses = [];
  List wards = [];
  List beds = [];
  bool _autoSearched = false;
  int? doctorId;
  int? nurseId;
  int? wardId;
  int? bedId;
  bool loading = false;
  String hospitalName = '';
  String hospitalPlace = '';
  String hospitalPhoto = '';
  String hospitalId = '';
  Map<String, dynamic>? selectedPatient;
  final addressCtrl = TextEditingController();
  Map<String, dynamic>? admissionResult;
  bool showSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadHospitalInfo();
    loadInitialData();

    phoneCtrl.addListener(_refresh);
    nameCtrl.addListener(_refresh);
    dobCtrl.addListener(_refresh);
    reasonCtrl.addListener(_refresh);
    addressCtrl.addListener(_refresh);
  }

  void _refresh() {
    final phone = phoneCtrl.text.trim();
    if (phone.length == 10 && !_autoSearched) {
      _autoSearched = true;
      searchPatient();
    }
    if (phone.length < 10) {
      _autoSearched = false;
      patientsFound.clear();
      selectedPatientId = null;
    }

    setState(() {});
  }

  void resetForm() {
    _formKey.currentState?.reset();

    phoneCtrl.clear();
    nameCtrl.clear();
    dobCtrl.clear();
    addressCtrl.clear();
    reasonCtrl.clear();
    admitByNameCtrl.clear();
    admitByPhoneCtrl.clear();
    admitByRelationCtrl.clear();

    patientsFound.clear();
    selectedPatientId = null;
    selectedPatient = null;

    doctorId = null;
    nurseId = null;
    wardId = null;
    bedId = null;
    gender = null;

    setState(() {
      showSuccess = false;
      admissionResult = null;
    });
  }

  Future<void> shareToWhatsApp(String phone, String message) async {
    final url = "https://wa.me/91$phone?text=${Uri.encodeComponent(message)}";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("WhatsApp not available")));
    }
  }

  Future<void> loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId');
    final d = await http.get(
      Uri.parse("$baseUrl/admissions/$hospitalId/staff/doctors"),
    );
    final n = await http.get(
      Uri.parse("$baseUrl/admissions/$hospitalId/staff/nurses"),
    );
    final w = await http.get(
      Uri.parse("$baseUrl/wards/$hospitalId/available-beds"),
    );

    setState(() {
      doctors = jsonDecode(d.body);
      nurses = jsonDecode(n.body);
      wards = jsonDecode(w.body);
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

  Future<void> searchPatient() async {
    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId');
    final res = await http.get(
      Uri.parse(
        "$baseUrl/admissions/patients/by-phone/${phoneCtrl.text}/$hospitalId",
      ),
    );

    if (res.statusCode == 200) {
      setState(() {
        patientsFound = jsonDecode(res.body);
        selectedPatientId = null;
      });
    }
  }

  Future<void> _pickDob() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: royal,
              onPrimary: Colors.white,
              onSurface: royal,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        dobCtrl.text =
            "${pickedDate.year.toString().padLeft(4, '0')}-"
            "${pickedDate.month.toString().padLeft(2, '0')}-"
            "${pickedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> submitAdmission() async {
    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId');
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final payload = {
      if (selectedPatientId != null)
        "patientId": selectedPatientId
      else
        "patient": {
          "name": nameCtrl.text,
          "phone": [phoneCtrl.text],
          "gender": gender,
          "dob": dobCtrl.text,
          "address": addressCtrl.text,
        },
      "doctorId": doctorId,
      "nurseId": nurseId,
      "bedId": bedId,
      "reason": reasonCtrl.text,
      if (admitByNameCtrl.text.isNotEmpty)
        "admitBy": {
          "name": admitByNameCtrl.text,
          "phone": admitByPhoneCtrl.text,
          "relation": admitByRelationCtrl.text,
        },
    };

    final res = await http.post(
      Uri.parse("$baseUrl/admissions/$hospitalId/admit"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    setState(() => loading = false);

    if (res.statusCode == 201 || res.statusCode == 200) {
      setState(() {
        admissionResult = jsonDecode(res.body);
        showSuccess = true;
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Admission failed")));
    }
  }

  Widget buildSuccessView() {
    final p = admissionResult;

    if (p == null) {
      return const Center(child: Text("No admission data"));
    }

    final patientPhone =
        (p["patient"]?["phone"]["mobile"] is List &&
            p["patient"]["phone"]["mobile"].isNotEmpty)
        ? p["patient"]["phone"]["mobile"][0]
        : "";

    final admissionId = p["id"]?.toString() ?? "N/A";

    final message =
        '''
🏥 $hospitalName

Patient admitted successfully.

Admission ID: $admissionId
Patient: ${p["patient"]?["name"] ?? ""}
Doctor: ${p["doctor"]?["name"] ?? ""}
Ward: ${p["bed"]?["ward"]?["name"] ?? ""}
Bed: ${p["bed"]?["bedNo"] ?? ""}
Reason: ${p["reason"] ?? ""}
''';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          /// 🏥 Hospital Card
          buildHospitalCard(
            hospitalName: hospitalName,
            hospitalPlace: hospitalPlace,
            hospitalPhoto: hospitalPhoto,
          ),

          const SizedBox(height: 20),

          const Icon(Icons.check_circle, color: Colors.green, size: 80),
          const SizedBox(height: 10),

          const Text(
            "Patient Admitted Successfully",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  successRow("Admission ID", admissionId),
                  successRow("Patient", p["patient"]?["name"] ?? "N/A"),
                  successRow("Doctor", p["doctor"]?["name"] ?? "N/A"),
                  successRow("Nurse", p["nurse"]?["name"] ?? "N/A"),
                  successRow("Ward", p["bed"]?["ward"]?["name"] ?? "N/A"),
                  successRow(
                    "Bed",
                    p["bed"] != null ? "Bed ${p["bed"]["bedNo"] ?? ""}" : "N/A",
                  ),
                  successRow("Reason", p["reason"] ?? ""),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// 📤 WhatsApp Share
          if (patientPhone.isNotEmpty)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.share, color: Colors.white),
                label: const Text("Share on WhatsApp"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () => shareToWhatsApp(patientPhone, message),
              ),
            ),

          const SizedBox(height: 12),

          /// ❌ Close
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: royal),
              onPressed: resetForm,
              child: const Text("Close", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget successRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  bool isFormComplete() {
    if (doctorId == null || nurseId == null || bedId == null) return false;
    if (reasonCtrl.text.isEmpty) return false;

    if (patientsFound.isNotEmpty) {
      return selectedPatientId != null;
    } else {
      return nameCtrl.text.isNotEmpty &&
          dobCtrl.text.isNotEmpty &&
          gender != null &&
          addressCtrl.text.isNotEmpty;
    }
  }

  Widget labeledField({required String label, required Widget field}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: royal, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: field),
        ],
      ),
    );
  }

  Widget buildAdmissionForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          buildHospitalCard(
            hospitalName: hospitalName,
            hospitalPlace: hospitalPlace,
            hospitalPhoto: hospitalPhoto,
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: royal),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        "Patient Details",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: royal,
                        ),
                      ),
                    ),
                    labeledField(
                      label: "Phone",
                      field: TextFormField(
                        controller: phoneCtrl,
                        cursorColor: royal,
                        style: const TextStyle(color: royal),
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        buildCounter:
                            (
                              _, {
                              required int currentLength,
                              required bool isFocused,
                              int? maxLength,
                            }) => null,
                        decoration: _inputDecoration("Enter phone number"),
                        validator: (v) =>
                            v!.length != 10 ? "Enter 10 digit number" : null,
                      ),
                    ),

                    if (phoneCtrl.text.length == 10 && patientsFound.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          "No patient found. Please add details.",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),

                    const SizedBox(height: 10),
                    if (patientsFound.isNotEmpty)
                      labeledField(
                        label: "Patient",
                        field: styledDropdown<int>(
                          hint: "Select patient",
                          value: selectedPatientId,
                          items: patientsFound
                              .map<DropdownMenuItem<int>>(
                                (p) => DropdownMenuItem(
                                  value: p["id"],
                                  child: Text(
                                    p["name"],
                                    style: const TextStyle(color: royal),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            final patient = patientsFound.firstWhere(
                              (p) => p["id"] == v,
                            );

                            setState(() {
                              selectedPatientId = v;
                              selectedPatient = patient;

                              nameCtrl.text = patient["name"] ?? "";

                              dobCtrl.text = patient["dob"] != null
                                  ? patient["dob"].toString().split("T")[0]
                                  : "";

                              gender = patient["gender"];

                              // ✅ ADDRESS AUTO-FILL
                              addressCtrl.text =
                                  patient["address"]["Address"] ?? "";
                            });
                          },
                          validator: (v) => v == null ? "Select patient" : null,
                        ),
                      ),

                    Column(
                      children: [
                        Column(
                          children: [
                            labeledField(
                              label: "Name",
                              field: TextFormField(
                                controller: nameCtrl,
                                cursorColor: royal,
                                style: const TextStyle(color: royal),
                                decoration: _inputDecoration("Patient name"),
                                validator: (v) =>
                                    v!.isEmpty ? "Required" : null,
                              ),
                            ),

                            labeledField(
                              label: "DOB",
                              field: TextFormField(
                                controller: dobCtrl,
                                readOnly: true,
                                cursorColor: royal,
                                style: const TextStyle(color: royal),
                                decoration:
                                    _inputDecoration(
                                      "Select date of birth",
                                    ).copyWith(
                                      suffixIcon: const Icon(
                                        Icons.calendar_today,
                                        color: royal,
                                      ),
                                    ),
                                onTap: _pickDob,
                                validator: (v) =>
                                    v!.isEmpty ? "Required" : null,
                              ),
                            ),

                            labeledField(
                              label: "Gender",
                              field: styledDropdown<String>(
                                hint: "Select gender",
                                value: gender,
                                items: const [
                                  DropdownMenuItem(
                                    value: "Male",
                                    child: Text("Male"),
                                  ),
                                  DropdownMenuItem(
                                    value: "Female",
                                    child: Text("Female"),
                                  ),
                                  DropdownMenuItem(
                                    value: "Others",
                                    child: Text("Others"),
                                  ),
                                ],
                                onChanged: (v) => setState(() => gender = v),
                                validator: (v) => v == null ? "Required" : null,
                              ),
                            ),
                            labeledField(
                              label: "Address",
                              field: TextFormField(
                                controller: addressCtrl,
                                maxLines: 2,
                                cursorColor: royal,
                                style: const TextStyle(color: royal),
                                decoration: _inputDecoration(
                                  "House / Street / Area",
                                ),
                                validator: (v) =>
                                    v!.isEmpty ? "Required" : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Divider(height: 30),

                    // DOCTOR
                    labeledField(
                      label: "Doctor",
                      field: styledDropdown<int>(
                        hint: "Select doctor",
                        value: doctorId,
                        items: doctors
                            .map<DropdownMenuItem<int>>(
                              (d) => DropdownMenuItem(
                                value: d["id"],
                                child: Text(
                                  d["name"],
                                  style: const TextStyle(color: royal),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => doctorId = v),
                        validator: (v) => v == null ? "Required" : null,
                      ),
                    ),

                    // NURSE
                    labeledField(
                      label: "Nurse",
                      field: styledDropdown<int>(
                        hint: "Select nurse",
                        value: nurseId,
                        items: nurses
                            .map<DropdownMenuItem<int>>(
                              (n) => DropdownMenuItem(
                                value: n["id"],
                                child: Text(
                                  n["name"],
                                  style: const TextStyle(color: royal),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => nurseId = v),
                        validator: (v) => v == null ? "Required" : null,
                      ),
                    ),

                    // WARD
                    labeledField(
                      label: "Ward",
                      field: styledDropdown<int>(
                        hint: "Select ward",
                        value: wardId,
                        items: wards
                            .map<DropdownMenuItem<int>>(
                              (w) => DropdownMenuItem(
                                value: w["id"],
                                child: Text(
                                  w["name"],
                                  style: const TextStyle(color: royal),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            wardId = v;
                            beds = wards.firstWhere(
                              (w) => w["id"] == v,
                            )["beds"];
                          });
                        },
                        validator: (v) => v == null ? "Required" : null,
                      ),
                    ),

                    // BED
                    labeledField(
                      label: "Bed",
                      field: styledDropdown<int>(
                        hint: "Select bed",
                        value: bedId,
                        items: beds
                            .map<DropdownMenuItem<int>>(
                              (b) => DropdownMenuItem(
                                value: b["id"],
                                child: Text(
                                  "Bed ${b["bedNo"]}",
                                  style: const TextStyle(color: royal),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => bedId = v),
                        validator: (v) => v == null ? "Required" : null,
                      ),
                    ),

                    const Divider(height: 30),

                    const Center(
                      child: Text(
                        "Admission Details",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: royal,
                        ),
                      ),
                    ),

                    // REASON
                    labeledField(
                      label: "Reason",
                      field: TextFormField(
                        controller: reasonCtrl,
                        maxLines: 2,
                        cursorColor: royal,
                        style: TextStyle(color: royal),
                        decoration: _inputDecoration("Reason for admission"),
                        validator: (v) => v!.isEmpty ? "Required" : null,
                      ),
                    ),

                    const Divider(height: 30),

                    // ADMITTED BY
                    labeledField(
                      label: "Name",
                      field: TextFormField(
                        controller: admitByNameCtrl,
                        cursorColor: royal,
                        style: TextStyle(color: royal),
                        decoration: _inputDecoration("Admitted by name"),
                      ),
                    ),
                    labeledField(
                      label: "Phone",
                      field: TextFormField(
                        controller: admitByPhoneCtrl,
                        cursorColor: royal,
                        style: TextStyle(color: royal),
                        decoration: _inputDecoration("Admitted by phone"),
                      ),
                    ),
                    labeledField(
                      label: "Relation",
                      field: TextFormField(
                        controller: admitByRelationCtrl,
                        cursorColor: royal,
                        style: TextStyle(color: royal),
                        decoration: _inputDecoration(
                          "Father / Mother / Husband",
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // SUBMIT
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: royal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: (!isFormComplete() || loading)
                            ? null
                            : submitAdmission,
                        child: loading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Admit Patient",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void fillPatientDetails(Map patient) {
    nameCtrl.text = patient["name"] ?? "";

    // DOB comes as ISO string → extract date
    if (patient["dob"] != null) {
      dobCtrl.text = patient["dob"].toString().split("T").first;
    }

    gender = patient["gender"];

    setState(() {});
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: royal.withValues(alpha: 0.8)),
      filled: true,
      fillColor: royal.withValues(alpha: 0.1),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: royal, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: royal, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  DropdownButtonFormField<T> styledDropdown<T>({
    required String hint,
    required List<DropdownMenuItem<T>> items,
    ValueChanged<T?>? onChanged, // ✅ nullable
    FormFieldValidator<T>? validator,
    T? value,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      dropdownColor: Colors.white,
      iconEnabledColor: royal,
      style: const TextStyle(color: royal, fontWeight: FontWeight.w500),
      decoration: _inputDecoration(hint),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: royal,
        title: const Text(
          "Admit Patient",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: showSuccess ? buildSuccessView() : buildAdmissionForm(),
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
