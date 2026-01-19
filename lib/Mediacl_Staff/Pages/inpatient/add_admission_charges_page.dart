import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../../../../utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

const Color royal = Color(0xFFBF955E);
const Color royalLight = Color(0xFFC3A878);

class AddAdmissionChargesPage extends StatefulWidget {
  const AddAdmissionChargesPage({super.key});

  @override
  State<AddAdmissionChargesPage> createState() =>
      _AddAdmissionChargesPageState();
}

class _AddAdmissionChargesPageState extends State<AddAdmissionChargesPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isFetching = true;
  bool _showForm = false;

  int? _editingChargeId;
  int? _selectedAdmissionId;
  String hospitalName = '';
  String hospitalPlace = '';
  String hospitalPhoto = '';
  String hospitalId = '';
  List<Map<String, dynamic>> admittedAdmissions = [];
  List<Map<String, dynamic>> charges = [];

  @override
  void initState() {
    super.initState();
    _loadHospitalInfo();
    _loadData();
    fetchCharges();
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

  Future<void> _loadData() async {
    await fetchAdmittedAdmissions();
    setState(() => _isFetching = false);
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: royal)),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: royal, width: 2),
        ),
      ),
    );
  }

  // ================= FETCH ADMITTED ADMISSIONS =================
  Future<void> fetchAdmittedAdmissions() async {
    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId');
    final res = await http.get(
      Uri.parse('$baseUrl/admissions/$hospitalId/admitted'),
    );

    if (res.statusCode == 200) {
      admittedAdmissions = List<Map<String, dynamic>>.from(
        jsonDecode(res.body),
      );
      setState(() {});
    }
  }

  // ================= FETCH CHARGES =================
  Future<void> fetchCharges() async {
    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId');

    final res = await http.get(
      Uri.parse('$baseUrl/charges/hospital/$hospitalId/pending'),
    );

    if (res.statusCode == 200) {
      // The API already returns grouped by admission
      final List<dynamic> data = jsonDecode(res.body);

      setState(() {
        charges = data
            .map(
              (adm) => {
                "admissionId": adm["admissionId"],
                "patientName": adm["patientName"],
                "wardName": adm["wardName"],
                "bedNo": adm["bedNo"],
                "charges": List<Map<String, dynamic>>.from(adm["charges"]),
              },
            )
            .toList();
      });
    }
  }

  // ================= SUBMIT =================
  Future<void> submitCharge() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final body = {
      "admissionId": _selectedAdmissionId,
      "description": _descriptionCtrl.text.trim(),
      "amount": double.parse(_amountCtrl.text.trim()),
    };

    try {
      http.Response res;
      if (_editingChargeId == null) {
        res = await http.post(
          Uri.parse('$baseUrl/charges'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(body),
        );
      } else {
        res = await http.patch(
          Uri.parse('$baseUrl/charges/$_editingChargeId'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(body),
        );
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        showMessage("✅ Charge saved");
        _resetForm();
        fetchCharges();
      } else {
        showMessage("❌ Failed");
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _descriptionCtrl.clear();
    _amountCtrl.clear();
    _editingChargeId = null;
    _showForm = false;
  }

  // ================= DELETE =================
  Future<void> deleteCharge(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/charges/$id'));

    if (res.statusCode == 200) {
      charges.removeWhere((e) => e["id"] == id);
      setState(() {});
      showMessage("✅ Deleted");
    }
  }

  // ================= UI =================
  Widget buildDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedAdmissionId,
      decoration: inputDecoration("Select Admission"),
      style: const TextStyle(color: royal),
      items: admittedAdmissions.map((a) {
        return DropdownMenuItem<int>(
          value: a['id'],
          child: Text(
            "${a['patient']['name']} | Ward ${a['bed']['ward']['name']} - Bed ${a['bed']['bedNo']}",
          ),
        );
      }).toList(),
      onChanged: (v) {
        setState(() {
          _selectedAdmissionId = v;
          charges.clear();
        });
        if (v != null) fetchCharges();
      },
      validator: (v) => v == null ? "Select admission" : null,
    );
  }

  Widget buildForm() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: royal),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              buildDropdown(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionCtrl,
                cursorColor: royal,
                decoration: inputDecoration("Charge Description"),
                style: const TextStyle(color: royal),
                validator: (v) => v!.isEmpty ? "Enter description" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountCtrl,
                cursorColor: royal,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: inputDecoration("Amount"),
                style: const TextStyle(color: royal),
                inputFormatters: [
                  // Allow only numbers and decimal point
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return "Enter amount";
                  if (double.tryParse(v) == null) return "Enter a valid number";
                  return null;
                },
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: royal,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isLoading ? null : submitCharge,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _editingChargeId == null
                                  ? "Add Charge"
                                  : "Update Charge",
                            ),
                    ),
                  ),
                  TextButton(
                    onPressed: _resetForm,
                    child: const Text("Cancel", style: TextStyle(color: royal)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCharges() {
    return Column(
      children: charges.map((admission) {
        final List<Map<String, dynamic>> admissionCharges =
            List<Map<String, dynamic>>.from(admission['charges']);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: royal),
          ),
          child: ExpansionTile(
            title: Text(
              "${admission['patientName']} | Ward ${admission['wardName']} - Bed ${admission['bedNo']}",
              style: const TextStyle(color: royal, fontWeight: FontWeight.bold),
            ),
            children: admissionCharges.map((c) {
              return ListTile(
                title: Text(
                  c['description'].toUpperCase(),
                  style: const TextStyle(color: royal),
                ),
                subtitle: Text(
                  "₹${c['amount']}",
                  style: const TextStyle(
                    color: royal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: royal),
                      onPressed: () {
                        setState(() {
                          _editingChargeId = c['id'];
                          _descriptionCtrl.text = c['description'];
                          _amountCtrl.text = c['amount'].toString();
                          _showForm = true;
                          _selectedAdmissionId = admission['admissionId'];
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: royal),
                      onPressed: () => deleteCharge(c['id']),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: royal),
      filled: true,
      fillColor: royalLight.withValues(alpha: 0.05),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: royal),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: royal, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: royal,
        title: const Text(
          "Admission Charges",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator(color: royal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  buildHospitalCard(
                    hospitalName: hospitalName,
                    hospitalPlace: hospitalPlace,
                    hospitalPhoto: hospitalPhoto,
                  ),
                  const SizedBox(height: 18),
                  if (!_showForm)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: royal,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => setState(() => _showForm = true),
                      child: const Text("Add Charge"),
                    ),
                  if (_showForm) buildForm(),
                  const SizedBox(height: 16),
                  buildCharges(),
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
