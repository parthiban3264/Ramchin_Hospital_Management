// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:intl/intl.dart';
//
// import '../../../Pages/NotificationsPage.dart';
// import '../../../Services/Scan_Test_Get-Service.dart';
//
// class AddScanAndTestPage extends StatefulWidget {
//   const AddScanAndTestPage({Key? key}) : super(key: key);
//
//   @override
//   _AddScanAndTestPageState createState() => _AddScanAndTestPageState();
// }
//
// class _AddScanAndTestPageState extends State<AddScanAndTestPage> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _titleController = TextEditingController();
//   final TextEditingController _amountController = TextEditingController();
//   final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
//
//   String? selectedType;
//   List<dynamic> testOptions = [];
//   List<dynamic> selectedOptions = [];
//   String? _dateTime;
//
//   bool isLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _updateTime();
//   }
//
//   void _updateTime() {
//     setState(() {
//       _dateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
//     });
//   }
//
//   Future<void> _saveForm() async {
//     if (!_formKey.currentState!.validate()) return;
//     if (selectedOptions.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Please select at least one test option')),
//       );
//       return;
//     }
//
//     try {
//       final hospitalId = await secureStorage.read(key: 'hospitalId');
//       final newTestScanData = {
//         'hospital_Id': int.parse(hospitalId!),
//         'title': _titleController.text,
//         'options': selectedOptions,
//         'type': selectedType ?? 'TEST',
//         'amount': double.tryParse(_amountController.text),
//         'crearedAt': _dateTime.toString(),
//       };
//       final result = ScanTestGetService().createTestScan(newTestScanData);
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Scan and Test added successfully')),
//       );
//       Navigator.pop(context, true);
//     } catch (e) {
//
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Failed to add scan and test')));
//     }
//   }
//
//   Widget _buildOptionSelector() {
//     if (isLoading) return const Center(child: CircularProgressIndicator());
//     if (testOptions.isEmpty) return const Text('No test options available');
//
//     return Column(
//       children: testOptions.map((option) {
//         bool isSelected = selectedOptions.contains(option);
//         return CheckboxListTile(
//           title: Text("${option['name']} (\$${option['price']})"),
//           value: isSelected,
//           onChanged: (bool? selected) {
//             setState(() {
//               if (selected == true) {
//                 selectedOptions.add(option);
//               } else {
//                 selectedOptions.removeWhere((o) => o['name'] == option['name']);
//               }
//             });
//           },
//         );
//       }).toList(),
//     );
//   }
//
//   @override
//   void dispose() {
//     _titleController.dispose();
//     _amountController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     const Color gold = Color(0xFFBF955E);
//     return Scaffold(
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(100),
//         child: Container(
//           height: 100,
//           decoration: BoxDecoration(
//             color: gold,
//             borderRadius: const BorderRadius.only(
//               bottomLeft: Radius.circular(16),
//               bottomRight: Radius.circular(16),
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.15),
//                 blurRadius: 6,
//                 offset: const Offset(0, 3),
//               ),
//             ],
//           ),
//           child: SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               child: Row(
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                   Text(
//                     "Add Scan & Test",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const Spacer(),
//                   IconButton(
//                     icon: const Icon(Icons.notifications, color: Colors.white),
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => const NotificationPage(),
//                         ),
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: ListView(
//             children: [
//               TextFormField(
//                 controller: _titleController,
//                 decoration: const InputDecoration(labelText: 'Title'),
//                 validator: (value) => value == null || value.isEmpty
//                     ? 'Please enter title'
//                     : null,
//               ),
//               const SizedBox(height: 16),
//               TextFormField(
//                 controller: _amountController,
//                 decoration: const InputDecoration(labelText: 'Amount'),
//                 keyboardType: TextInputType.number,
//                 validator: (value) => value == null || value.isEmpty
//                     ? 'Please enter amount'
//                     : null,
//               ),
//               const SizedBox(height: 16),
//               DropdownButtonFormField<String>(
//                 value: selectedType,
//                 decoration: const InputDecoration(labelText: 'Type'),
//                 items: const [
//                   DropdownMenuItem(value: 'TEST', child: Text('TEST')),
//                   DropdownMenuItem(value: 'OTHER', child: Text('OTHER')),
//                 ],
//                 onChanged: (value) => setState(() => selectedType = value),
//                 validator: (value) =>
//                     value == null ? 'Please select a type' : null,
//               ),
//               const SizedBox(height: 16),
//               const Text(
//                 'Select Tests',
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//               _buildOptionSelector(),
//               const SizedBox(height: 24),
//               ElevatedButton(
//                 onPressed: _saveForm,
//                 child: const Text('Add Scan & Test'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Pages/NotificationsPage.dart';
import '../../../Services/Scan_Test_Get-Service.dart';

class AddScanAndTestPage extends StatefulWidget {
  const AddScanAndTestPage({super.key});

  @override
  State<AddScanAndTestPage> createState() => _AddScanAndTestPageState();
}

class _AddScanAndTestPageState extends State<AddScanAndTestPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  String selectedType = 'TEST';

  /// OPTIONS STORED AS JSON (NO MODEL)
  List<Map<String, dynamic>> selectedOptions = [];

  /// LIST FROM API
  List<dynamic> scanTestList = [];

  bool isLoading = false;
  int? editingId;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
    fetchScanTests();
  }

  /// ---------------- FETCH ----------------
  Future<void> fetchScanTests() async {
    setState(() => isLoading = true);
    scanTestList = await ScanTestGetService().fetchTests('SCAN');
    setState(() => isLoading = false);
  }

  /// ---------------- CREATE / UPDATE ----------------
  Future<void> saveScanTest() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedOptions.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Add at least one option")));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final hospitalId = prefs.getString('hospitalId');
    final body = {
      "hospital_Id": int.parse(hospitalId!),
      "title": _titleController.text,
      "type": selectedType,
      "status": "ACTIVE",
      "options": selectedOptions,
      "amount": double.parse(_amountController.text),
      "updatedAt": DateTime.now().toIso8601String(),
    };

    if (editingId == null) {
      body["createdAt"] = DateTime.now().toIso8601String();
      //await ScanTestGetService().createTestScan(body);
    } else {
      await ScanTestGetService().updateScanTest(editingId!, body);
    }

    clearForm();
    fetchScanTests();
    _tabController.animateTo(1);
  }

  /// ---------------- DELETE ----------------
  Future<void> deleteScanTest(int id) async {
    await ScanTestGetService().deleteScanTest(id);
    fetchScanTests();
  }

  /// ---------------- EDIT ----------------
  void editScanTest(dynamic item) {
    setState(() {
      editingId = item['id'];
      _titleController.text = item['title'];
      _amountController.text = item['amount'].toString();
      selectedType = item['type'];
      selectedOptions = List<Map<String, dynamic>>.from(
        jsonDecode(item['options']),
      );
      _tabController.animateTo(0);
    });
  }

  /// ---------------- CLEAR ----------------
  void clearForm() {
    editingId = null;
    _titleController.clear();
    _amountController.clear();
    selectedOptions.clear();
  }

  /// ---------------- OPTION UI ----------------
  Widget optionList() {
    return Column(
      children: selectedOptions.map((opt) {
        return Card(
          child: ListTile(
            title: Text("${opt['name']}"),
            subtitle: Text("₹${opt['price']}"),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => setState(() => selectedOptions.remove(opt)),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// ---------------- ADD TAB ----------------
  Widget addTab() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: "Title"),
            validator: (v) => v!.isEmpty ? "Required" : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: "Amount"),
            keyboardType: TextInputType.number,
            validator: (v) => v!.isEmpty ? "Required" : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedType,
            items: const [
              DropdownMenuItem(value: 'TEST', child: Text("TEST")),
              DropdownMenuItem(value: 'SCAN', child: Text("SCAN")),
            ],
            onChanged: (v) => setState(() => selectedType = v!),
          ),
          const SizedBox(height: 16),

          /// ADD OPTION
          ElevatedButton(
            onPressed: () {
              setState(() {
                selectedOptions.add({"name": "New Option", "price": 100});
              });
            },
            child: const Text("Add Option"),
          ),

          optionList(),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: saveScanTest,
            child: Text(editingId == null ? "ADD" : "UPDATE"),
          ),
        ],
      ),
    );
  }

  /// ---------------- MODIFY TAB ----------------
  Widget modifyTab() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (scanTestList.isEmpty) {
      return const Center(child: Text("No Data Found"));
    }

    return ListView.builder(
      itemCount: scanTestList.length,
      itemBuilder: (_, i) {
        final item = scanTestList[i];
        return Card(
          child: ListTile(
            title: Text(item['title']),
            subtitle: Text("₹${item['amount']}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => editScanTest(item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => deleteScanTest(item['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ---------------- BUILD ----------------
  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFBF955E);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 100,

          decoration: const BoxDecoration(
            color: gold,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  "Add Scan & Test",
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

      /// -------- BOTTOM TABS --------
      bottomNavigationBar: TabBar(
        controller: _tabController,
        labelColor: gold,
        tabs: const [
          Tab(text: "ADD"),
          Tab(text: "MODIFY"),
        ],
      ),

      body: TabBarView(
        controller: _tabController,
        children: [addTab(), modifyTab()],
      ),
    );
  }
}
