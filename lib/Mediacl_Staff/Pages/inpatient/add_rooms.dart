import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../../../../utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color royal = Color(0xFFBF955E);

class WardsPage extends StatefulWidget {
  const WardsPage({super.key});

  @override
  State<WardsPage> createState() => _WardsPageState();
}

class _WardsPageState extends State<WardsPage> {
  final _formKey = GlobalKey<FormState>();

  bool _showForm = false;
  bool _loading = false;
  final TextEditingController wardRentController = TextEditingController();

  Map<String, dynamic>? _editingWard;

  final TextEditingController wardNameController = TextEditingController();
  String? selectedWardType;

  List<Map<String, dynamic>> wards = [];
  String hospitalName = '';
  String hospitalPlace = '';
  String hospitalPhoto = '';
  String hospitalId = '';

  List<TextEditingController> bedNoControllers = [];
  List<String> bedStatusValues = [];

  @override
  void initState() {
    super.initState();
    _loadHospitalInfo();
    fetchWards();
  }

  Future<void> fetchWards() async {
    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId');
    final res = await http.get(Uri.parse("$baseUrl/wards/all/$hospitalId"));
    if (res.statusCode == 200) {
      setState(() {
        wards = List<Map<String, dynamic>>.from(jsonDecode(res.body));
      });
    }
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

  Future<void> deleteWard(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId');
    await http.delete(Uri.parse("$baseUrl/wards/$id/$hospitalId"));
    fetchWards();
  }

  Future<void> saveWard() async {
    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId');
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final bedsPayload = List.generate(bedNoControllers.length, (i) {
      return {
        if (_editingWard != null &&
            _editingWard!["beds"] != null &&
            i < _editingWard!["beds"].length)
          "id": _editingWard!["beds"][i]["id"],
        "bedNo": int.parse(bedNoControllers[i].text),
        "status": bedStatusValues[i],
      };
    });
    // final bedsPayload = List.generate(bedNoControllers.length, (i) {
    //   return {
    //     if (_editingWard != null &&
    //         _editingWard!["beds"] != null &&
    //         i < _editingWard!["beds"].length)
    //       "id": _editingWard!["beds"][i]["id"],
    //     "bedNo": int.parse(bedNoControllers[i].text),
    //     "status": bedStatusValues[i],
    //   };
    // });
    http.Response response;

    if (_editingWard == null) {
      response = await http.post(
        Uri.parse("$baseUrl/wards/$hospitalId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": wardNameController.text.trim(),
          "type": selectedWardType,
          "rent": double.tryParse(wardRentController.text.trim()) ?? 0,
          "beds": bedsPayload,
        }),
      );
    } else {
      response = await http.patch(
        Uri.parse(
          "$baseUrl/wards/${_editingWard!['id']}/fullUpdate/$hospitalId",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": wardNameController.text.trim(),
          "type": selectedWardType,
          "rent": double.tryParse(wardRentController.text.trim()) ?? 0,
          "beds": bedsPayload,
        }),
      );
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      resetForm();
      fetchWards();
    }

    setState(() => _loading = false);
  }

  void resetForm() {
    setState(() {
      _showForm = false;
      _editingWard = null;
      wardNameController.clear();
      selectedWardType = null;
      bedNoControllers.clear();
      bedStatusValues.clear();
      wardRentController.clear();
    });
  }

  void addWard() {
    setState(() {
      _editingWard = null;
      _showForm = true;
      wardNameController.clear();
      selectedWardType = null;
      wardRentController.clear();
      bedNoControllers = [TextEditingController()];
      bedStatusValues = ["AVAILABLE"];
    });
  }

  void editWard(Map<String, dynamic> ward) {
    setState(() {
      _editingWard = ward;
      _showForm = true;

      wardNameController.text = ward["name"];
      selectedWardType = ward["type"];
      wardRentController.text = ward["rent"]?.toString() ?? "";

      bedNoControllers.clear();
      bedStatusValues.clear();

      for (final bed in ward["beds"]) {
        bedNoControllers.add(
          TextEditingController(text: bed["bedNo"].toString()),
        );
        bedStatusValues.add(bed["status"]);
      }
    });
  }

  Widget bedRow(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          /// BED NUMBER
          Expanded(
            child: TextFormField(
              controller: bedNoControllers[index],
              keyboardType: TextInputType.number,
              cursorColor: royal,
              style: const TextStyle(color: royal),
              decoration: InputDecoration(
                labelText: "Bed ${index + 1}",
                labelStyle: const TextStyle(color: royal),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: royal, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: royal, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: royal.withValues(alpha: 0.02),
              ),
              validator: (v) => v == null || v.isEmpty ? "Required" : null,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Expanded(
              child: DropdownButtonFormField<String>(
                value: bedStatusValues[index],
                dropdownColor: Colors.white,
                style: const TextStyle(color: royal),
                iconEnabledColor: royal,
                decoration: InputDecoration(
                  labelText: "Status",
                  labelStyle: const TextStyle(color: royal),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: royal, width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: royal, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: bedStatusValues[index] == "OCCUPIED"
                      ? Colors.grey.withValues(alpha: 0.1)
                      : royal.withValues(alpha: 0.02),
                ),

                /// 🔒 DISABLE IF OCCUPIED
                onChanged: bedStatusValues[index] == "OCCUPIED"
                    ? null
                    : (v) => setState(() => bedStatusValues[index] = v!),

                items: const [
                  DropdownMenuItem(
                    value: "AVAILABLE",
                    child: Text("AVAILABLE"),
                  ),
                  DropdownMenuItem(value: "OCCUPIED", child: Text("OCCUPIED")),
                  DropdownMenuItem(
                    value: "MAINTENANCE",
                    child: Text("MAINTENANCE"),
                  ),
                ],
              ),
            ),
          ),

          /// DELETE
          IconButton(
            icon: const Icon(Icons.delete, color: royal),
            tooltip: "Remove Bed",
            onPressed: () {
              setState(() {
                bedNoControllers.removeAt(index);
                bedStatusValues.removeAt(index);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget wardForm() {
    return Card(
      elevation: 8,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: royal, width: 1),
      ),
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// TITLE
              Center(
                child: Text(
                  _editingWard == null ? "Add Ward & Beds" : "Edit Ward & Beds",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: royal,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// WARD NAME
              TextFormField(
                controller: wardNameController,
                cursorColor: royal,
                style: const TextStyle(color: royal),
                decoration: InputDecoration(
                  labelText: "Ward Name",
                  labelStyle: const TextStyle(color: royal),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: royal),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: royal, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: royal.withValues(alpha: 0.02),
                ),
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 12),

              /// WARD TYPE
              DropdownButtonFormField<String>(
                value: selectedWardType,
                dropdownColor: Colors.white,
                style: const TextStyle(color: royal),
                iconEnabledColor: royal,
                decoration: InputDecoration(
                  labelText: "Ward Type",
                  labelStyle: const TextStyle(color: royal),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: royal),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: royal, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: royal.withValues(alpha: 0.02),
                ),
                items: const [
                  DropdownMenuItem(value: "General", child: Text("General")),
                  DropdownMenuItem(
                    value: "Emergency",
                    child: Text("Emergency"),
                  ),
                  DropdownMenuItem(value: "Private", child: Text("Private")),
                ],
                onChanged: (v) => setState(() => selectedWardType = v),
                validator: (v) => v == null ? "Required" : null,
              ),
              const SizedBox(height: 12),

              /// WARD RENT
              TextFormField(
                controller: wardRentController,
                keyboardType: TextInputType.number,
                cursorColor: royal,
                style: const TextStyle(color: royal),
                decoration: InputDecoration(
                  labelText: "Ward Rent",
                  labelStyle: const TextStyle(color: royal),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: royal),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: royal, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: royal.withValues(alpha: 0.02),
                ),
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 18),

              /// BEDS TITLE
              const Center(
                child: Text(
                  "Add Beds",
                  style: TextStyle(
                    color: royal,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              /// BED LIST
              ...List.generate(bedNoControllers.length, bedRow),

              const SizedBox(height: 8),

              /// ADD BED BUTTON
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: royal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      bedNoControllers.add(TextEditingController());
                      bedStatusValues.add("AVAILABLE");
                    });
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    "Add Bed",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// ACTION BUTTONS
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: royal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _loading ? null : saveWard,
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _editingWard == null
                                  ? "Save Ward"
                                  : "Update Ward",
                              style: const TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: resetForm,
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

  void showDeleteWardDialog(Map<String, dynamic> ward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: royal, width: 1.5),
        ),
        title: const Text(
          "Delete Ward",
          style: TextStyle(color: royal, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Do you want to delete this ward?",
              style: TextStyle(color: royal),
            ),
            const SizedBox(height: 10),
            Text(
              "Name: ${ward["name"]}",
              style: const TextStyle(color: royal, fontWeight: FontWeight.w600),
            ),
            Text("Type: ${ward["type"]}", style: const TextStyle(color: royal)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: royal)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: royal),
            onPressed: () async {
              Navigator.pop(context); // close dialog
              await deleteWard(ward["id"]);
            },
            child: const Text("OK", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget wardCard(Map<String, dynamic> ward) {
    final beds = ward["beds"] as List? ?? [];

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: royal, width: 1.5),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER ROW
            Row(
              children: [
                Expanded(
                  child: Text(
                    ward["name"],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: royal,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: royal),
                  onPressed: () => editWard(ward),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: royal),
                  onPressed: () => showDeleteWardDialog(ward),
                ),
              ],
            ),

            const SizedBox(height: 4),

            Text(
              "Type: ${ward["type"]} • Rent: ₹${ward["rent"] ?? 0}",
              style: const TextStyle(color: royal),
            ),

            const SizedBox(height: 10),
            const Text(
              "Beds",
              style: TextStyle(fontWeight: FontWeight.bold, color: royal),
            ),
            const SizedBox(height: 6),

            /// BED LIST
            if (beds.isEmpty)
              const Text("No beds added", style: TextStyle(color: royal))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: beds.map<Widget>((bed) {
                  final status = bed["status"];

                  Color statusColor;
                  switch (status) {
                    case "AVAILABLE":
                      statusColor = Colors.green;
                      break;
                    case "OCCUPIED":
                      statusColor = Colors.red;
                      break;
                    default:
                      statusColor = Colors.orange;
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: royal, width: 1),
                      color: statusColor.withValues(alpha: 0.08),
                    ),
                    child: Text(
                      "Bed ${bed["bedNo"]} • $status",
                      style: TextStyle(
                        color: royal,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: royal,
        title: const Text(
          "Ward & Bed Management",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
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
                onPressed: addWard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: royal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Add Ward",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            if (_showForm) wardForm(),

            const SizedBox(height: 16),
            ...wards.map(wardCard),
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
