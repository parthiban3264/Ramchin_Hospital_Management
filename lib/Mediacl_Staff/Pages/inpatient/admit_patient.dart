import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../../utils/utils.dart';
import '../../../Pages/NotificationsPage.dart';
import '../../../Services/admin_service.dart';

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
  final admitByNameCtrl = TextEditingController();
  final admitByPhoneCtrl = TextEditingController();
  final admitByRelationCtrl = TextEditingController();
  List wards = [];
  List beds = [];
  bool autoSearched = false;
  int? wardId;
  int? bedId;
  int? doctorId;
  int? nurseId;
  bool loading = false;
  String hospitalName = '';
  String hospitalPlace = '';
  String hospitalPhoto = '';
  String hospitalId = '';
  Map<String, dynamic>? selectedPatient;
  Map<String, dynamic>? admissionResult;
  bool showSuccess = false;
  bool bedLocked = false;
  Map<String, dynamic>? selectedWard;
  Map<String, dynamic>? selectedBed;
  Set<int> expandedWards = {};
  Map<String, Set<int>> selectedBeds = {};
  final patientIdCtrl = TextEditingController();
  bool isAdvancedPayment = true;
  bool changeDoctor = false;
  bool changeNurse = false;
  List<dynamic> nurseList = [];
  List<dynamic> doctorList = [];
  bool isLoadingPage = true;
  Timer? _searchTimer;
  bool _isUpdatingInternally = false;

  @override
  void initState() {
    super.initState();
    _loadHospitalInfo();
    loadInitialData();
    loadStaff();
    phoneCtrl.addListener(_onPhoneChanged);
    patientIdCtrl.addListener(_onPatientIdChanged);
    _updateTime();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    phoneCtrl.dispose();
    patientIdCtrl.dispose();
    admitByNameCtrl.dispose();
    admitByPhoneCtrl.dispose();
    admitByRelationCtrl.dispose();
    super.dispose();
  }

  String? _dateTime;
  void _updateTime() {
    setState(() {
      _dateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
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
      // ✅ SET DEFAULTS ONCE
      if (nurseList.isNotEmpty && nurseId == null) {
        nurseId = int.parse(nurseList.first['user_Id'].toString());
      }

      if (doctorList.isNotEmpty && doctorId == null) {
        doctorId = int.parse(doctorList.first['user_Id'].toString());
      }

      isLoadingPage = false;
    });
  }

  void _onPhoneChanged() {
    if (_isUpdatingInternally) return;

    final phone = phoneCtrl.text.trim();
    _searchTimer?.cancel();

    if (phone.length == 10) {
      _searchTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) searchPatientByPhone(phone);
      });
    } else if (phone.length < 10) {
      // PRE-EMPTIVE clear if we are moving away from a selected patient
      if (selectedPatientId != null) {
        _clearPatientSelection(showSnackbar: false);
      }
    }
  }

  void _onPatientIdChanged() {
    if (_isUpdatingInternally) return;

    final id = patientIdCtrl.text.trim();
    _searchTimer?.cancel();

    if (id.isNotEmpty) {
      // PRE-EMPTIVE clear if the current selection doesn't match the input
      if (selectedPatientId?.toString() != id && selectedPatientId != null) {
        _clearPatientSelection(showSnackbar: false);
      }

      _searchTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) searchPatientById(id);
      });
    } else {
      _clearPatientSelection(showSnackbar: false);
    }
  }

  Future<void> searchPatientById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId');

    setState(() => loading = true);

    final res = await http.get(
      Uri.parse("$baseUrl/admissions/patients/by-id/$id/$hospitalId"),
    );

    if (!mounted) return;
    setState(() => loading = false);

    // Only apply result if the user has not changed the Patient ID in the meantime
    // (avoids race: typing "2002" then late response for "200" overwriting to 200)
    final currentId = patientIdCtrl.text.trim();
    if (currentId != id) return;

    if (res.statusCode == 200 || res.statusCode == 201) {
      final patientRaw = jsonDecode(res.body);
      if (patientRaw != null && patientRaw is Map && patientRaw.isNotEmpty) {
        final Map<String, dynamic> patient = Map<String, dynamic>.from(
          patientRaw,
        );
        final returnedId = patient["id"]?.toString() ?? "";
        // If we got a result but it's not what we asked for, or it's empty, clear.
        if (returnedId != id) {
          _clearPatientSelection(showSnackbar: false);
          return;
        }

        String mobilePhone = patient["phone"]?["mobile"] ?? "";
        if (mobilePhone.startsWith("+91")) {
          mobilePhone = mobilePhone.substring(3).trim();
        }

        setState(() {
          _isUpdatingInternally = true;
          autoSearched = false;
          selectedPatientId = patient["id"];
          selectedPatient = patient;
          patientsFound = [patient];
          phoneCtrl.text = mobilePhone;

          final consultationList = patient['Consultation'] as List?;
          if (consultationList != null && consultationList.isNotEmpty) {
            final last = consultationList.last;
            final dId = int.tryParse(last['doctor_Id']?.toString() ?? "");
            if (dId != null) {
              doctorId = dId;
            }
          }
        });
        // Release lock after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _isUpdatingInternally = false;
        });
      } else {
        _clearPatientSelection();
      }
    } else {
      _clearPatientSelection();
    }
  }

  Future<void> searchPatientByPhone(String phone) async {
    final currentPhone = phoneCtrl.text.trim();
    if (currentPhone != phone) return;

    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId');

    setState(() => loading = true);

    final res = await http.get(
      Uri.parse("$baseUrl/admissions/patients/by-phone/$phone/$hospitalId"),
    );

    if (!mounted) return;
    setState(() => loading = false);

    // Guard against race condition
    if (phoneCtrl.text.trim() != phone) return;

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is List && decoded.isNotEmpty) {
        final patientRaw = decoded[0]; // auto-select first match
        if (patientRaw is! Map) {
          _clearPatientSelection();
          return;
        }

        final Map<String, dynamic> patient = Map<String, dynamic>.from(
          patientRaw,
        );

        String mobilePhone = patient["phone"]?["mobile"] ?? "";
        if (mobilePhone.startsWith("+91")) {
          mobilePhone = mobilePhone.substring(3).trim();
        }

        setState(() {
          _isUpdatingInternally = true;
          selectedPatientId = patient["id"];
          selectedPatient = patient;
          patientsFound = decoded;
          patientIdCtrl.text = patient["id"].toString();
          phoneCtrl.text = mobilePhone;

          final consultationList = patient['Consultation'] as List?;
          if (consultationList != null && consultationList.isNotEmpty) {
            final last = consultationList.last;
            final dId = int.tryParse(last['doctor_Id']?.toString() ?? "");
            if (dId != null) {
              doctorId = dId;
            }
          }
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _isUpdatingInternally = false;
        });
      } else {
        _clearPatientSelection();
      }
    } else {
      _clearPatientSelection();
    }
  }

  void _clearPatientSelection({bool showSnackbar = true}) {
    if (showSnackbar && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Patient not found")));
    }
    setState(() {
      _isUpdatingInternally = true;
      selectedPatientId = null;
      selectedPatient = null;
      patientsFound = [];
      phoneCtrl.clear();
      // Reset doctor/nurse to defaults if possible
      if (doctorList.isNotEmpty) {
        doctorId = int.tryParse(doctorList.first['user_Id'].toString());
      }
      if (nurseList.isNotEmpty) {
        nurseId = int.tryParse(nurseList.first['user_Id'].toString());
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isUpdatingInternally = false;
    });
  }

  // void _refresh() {
  //   final phone = phoneCtrl.text.trim();
  //   if (phone.length == 10 && !_autoSearched) {
  //     _autoSearched = true;
  //     searchPatient();
  //   }
  //   if (phone.length < 10) {
  //     _autoSearched = false;
  //     patientsFound.clear();
  //     selectedPatientId = null;
  //   }
  //
  //   setState(() {});
  // }

  void resetForm() {
    _formKey.currentState?.reset();

    phoneCtrl.clear();
    admitByNameCtrl.clear();
    admitByPhoneCtrl.clear();
    admitByRelationCtrl.clear();

    patientsFound.clear();
    selectedPatientId = null;
    selectedPatient = null;

    /// 🔥 CLEAR BED + WARD STATE
    wardId = null;
    bedId = null;
    selectedWard = null;
    selectedBed = null;
    selectedBeds.clear();
    expandedWards.clear();
    bedLocked = false;

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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("WhatsApp not available")));
      }
    }
  }

  Future<void> loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId');
    final w = await http.get(Uri.parse("$baseUrl/wards/all/$hospitalId"));

    setState(() {
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

  Future<void> submitAdmission() async {
    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId');
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final payload = {
      "patientId": selectedPatientId,
      "bedId": bedId,
      if (admitByNameCtrl.text.isNotEmpty)
        "admitBy": {
          "name": admitByNameCtrl.text,
          "phone": admitByPhoneCtrl.text,
          "relation": admitByRelationCtrl.text,
        },
      "createdAt": _dateTime.toString(),
      "staffChange": [
        {
          "doctor": doctorId.toString(),
          "nurse": nurseId.toString(),
          "dateTime": _dateTime.toString(),
        },
      ],
      "isAdvanced": isAdvancedPayment,
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
      final error = jsonDecode(res.body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error["message"] ?? "Admission failed"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget buildSuccessView() {
    final p = admissionResult;

    if (p == null) {
      return const Center(child: Text("No admission data"));
    }

    final patientPhone = p["patient"]?["phone"]?["mobile"] ?? "";
    final admissionId = p["id"]?.toString() ?? "N/A";

    final message =
        '''
🏥 $hospitalName

Patient admitted successfully.

Admission ID: $admissionId
Patient: ${p["patient"]?["name"] ?? ""}
Ward: ${p["bed"]?["ward"]?["name"] ?? ""}
Bed: ${p["bed"]?["bedNo"] ?? ""}
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
                  successRow("Ward", p["bed"]?["ward"]?["name"] ?? "N/A"),
                  successRow(
                    "Bed",
                    p["bed"] != null ? "Bed ${p["bed"]["bedNo"] ?? ""}" : "N/A",
                  ),
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
    if (selectedPatientId == null) return false;
    if (bedId == null) return false;
    return true;
  }

  Widget _buildWardCard(int index, dynamic ward) {
    final key = "${ward['id']}";
    final beds = List.from(ward['beds'] ?? []);

    final availableBeds = beds
        .where((b) => b['status'] == 'AVAILABLE')
        .toList();

    final selectedBedIds = selectedBeds[key] ?? {};
    final isExpanded = expandedWards.contains(index);

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: royal, width: 1),
      ),
      child: Column(
        children: [
          /// HEADER
          ListTile(
            title: Text(
              "${ward['type'] ?? 'Ward'} - ${ward['name']}",
              style: const TextStyle(
                color: royal,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              "Available: ${availableBeds.length} / ${beds.length}",
              style: const TextStyle(color: royal),
            ),
            trailing: Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: royal,
            ),
            onTap: () {
              setState(() {
                if (isExpanded) {
                  expandedWards.remove(index);
                } else {
                  expandedWards.add(index);
                }
              });
            },
          ),

          /// BED CHIPS
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: beds.map<Widget>((bed) {
                  final isAvailable = bed['status'] == 'AVAILABLE';
                  final isSelected = selectedBedIds.contains(bed['id']);

                  return ChoiceChip(
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Bed ${bed['bedNo']}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isAvailable
                                ? (isSelected ? Colors.white : royal)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: royal,
                    disabledColor: Colors.grey.shade300,
                    backgroundColor: Colors.green.shade100,
                    side: BorderSide(color: royal),
                    checkmarkColor: Colors.white,
                    onSelected: isAvailable
                        ? (_) {
                            setState(() {
                              /// SINGLE selection (admission case)
                              selectedBeds.clear();
                              selectedBeds[key] = {bed['id']};

                              selectedWard = ward;
                              selectedBed = bed;
                              wardId = ward['id'];
                              bedId = bed['id'];
                              bedLocked = true;
                            });
                          }
                        : null,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildWardBedSelection() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        buildHospitalCard(
          hospitalName: hospitalName,
          hospitalPlace: hospitalPlace,
          hospitalPhoto: hospitalPhoto,
        ),
        const SizedBox(height: 16),

        ...wards.asMap().entries.map((e) => _buildWardCard(e.key, e.value)),
      ],
    );
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
    final a = selectedPatient;
    print('a $a');
    final consultationList = a?['Consultation'] as List?;

    final consultationDoctorId =
        consultationList != null && consultationList.isNotEmpty
        ? consultationList.last['doctor_Id']
        : null;

    final doctor = doctorList.firstWhere(
      (e) => e['user_Id'] == consultationDoctorId,
      orElse: () => null,
    );

    final doctorText = doctor != null
        ? '${doctor['name']} • ${doctor['specialist']}'
        : (doctorList.isNotEmpty
              ? '${doctorList.first['name']} • ${doctorList.first['specialist']}'
              : 'No doctor selected');

    // Remove setState from build - logic moved to search/selection methods

    final nurseText = nurseList.first['name'];
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
                      label: "Patient ID",
                      field: TextFormField(
                        controller: patientIdCtrl,
                        cursorColor: royal,
                        style: const TextStyle(color: royal),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _inputDecoration("Enter Patient ID"),
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
                        decoration: _inputDecoration("Enter phone number"),
                      ),
                    ),

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
                            String mobilePhone =
                                patient["phone"]?["mobile"] ?? "";
                            if (mobilePhone.startsWith("+91")) {
                              mobilePhone = mobilePhone.substring(3).trim();
                            }

                            setState(() {
                              selectedPatientId = v;
                              selectedPatient = patient;
                              phoneCtrl.text =
                                  mobilePhone; // correctly set phone
                              patientIdCtrl.text = patient["id"].toString();

                              final consultationList =
                                  patient['Consultation'] as List?;
                              if (consultationList != null &&
                                  consultationList.isNotEmpty) {
                                final last = consultationList.last;
                                final dId = int.tryParse(
                                  last['doctor_Id']?.toString() ?? "",
                                );
                                if (dId != null) {
                                  doctorId = dId;
                                }
                              }
                            });
                          },
                          validator: (v) => v == null ? "Select patient" : null,
                        ),
                      ),

                    const Divider(height: 30),
                    if (bedLocked) ...[
                      const Center(
                        child: Text(
                          "Bed Allocation",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: royal,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      labeledField(
                        label: "Ward",
                        field: TextFormField(
                          enabled: true,
                          readOnly: true,
                          initialValue: selectedWard?["name"] ?? "",
                          decoration: _inputDecoration("Ward"),
                          style: const TextStyle(color: royal),
                        ),
                      ),

                      labeledField(
                        label: "Bed",
                        field: TextFormField(
                          enabled: true,
                          readOnly: true,
                          initialValue: "Bed ${selectedBed?["bedNo"] ?? ""}",
                          decoration: _inputDecoration("Bed"),
                          style: const TextStyle(color: royal),
                        ),
                      ),
                    ],

                    const Divider(height: 30),
                    if (bedLocked) ...[
                      const Center(
                        child: Text(
                          "HealthCare Professional",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: royal,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      _editableCard(
                        title: "Doctor",
                        value: doctorText,
                        changing: changeDoctor,
                        onTap: () =>
                            setState(() => changeDoctor = !changeDoctor),
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
                    ],
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

                    labeledField(
                      label: "Name",
                      field: TextFormField(
                        controller: admitByNameCtrl,
                        cursorColor: royal,
                        style: TextStyle(color: royal),
                        decoration: _inputDecoration("Attender name"),
                      ),
                    ),
                    labeledField(
                      label: "Phone",
                      field: TextFormField(
                        controller: admitByPhoneCtrl,
                        cursorColor: royal,
                        style: TextStyle(color: royal),
                        decoration: _inputDecoration("Attender phone"),
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

                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: CheckboxListTile(
                        value: isAdvancedPayment,
                        onChanged: (value) {
                          setState(() {
                            isAdvancedPayment = value!;
                          });
                        },
                        title: const Text(
                          "Advanced Payment",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          "Pay a partial amount in advance",
                          style: TextStyle(fontSize: 13),
                        ),
                        controlAffinity:
                            ListTileControlAffinity.trailing, // 👈 RIGHT SIDE
                        contentPadding: EdgeInsets.zero,
                        activeColor: Colors.green,
                      ),
                    ),

                    ///need to add check box default true store on varible
                    const SizedBox(height: 10),

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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: royal,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
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
                    "Admit Patient",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
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
      body: showSuccess
          ? buildSuccessView()
          : bedLocked
          ? buildAdmissionForm()
          : buildWardBedSelection(),
    );
  }
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
