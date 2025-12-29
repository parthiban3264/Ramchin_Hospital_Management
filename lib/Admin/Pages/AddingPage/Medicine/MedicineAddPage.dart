// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:intl/intl.dart';
//
// import '../../../../Pages/NotificationsPage.dart';
// import '../../../../Services/Medicine_Service.dart';
//
// class AddMedicianPage extends StatefulWidget {
//   const AddMedicianPage({Key? key}) : super(key: key);
//
//   @override
//   State<AddMedicianPage> createState() => _AddMedicianPageState();
// }
//
// class _AddMedicianPageState extends State<AddMedicianPage> {
//   final _formKey = GlobalKey<FormState>();
//   final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
//
//   int _currentIndex = 0;
//
//   final TextEditingController medicianNameController = TextEditingController();
//   final TextEditingController medicianCodeController = TextEditingController();
//   final TextEditingController stockController = TextEditingController();
//   final TextEditingController amountController = TextEditingController();
//   final TextEditingController expiryDateController = TextEditingController();
//   final TextEditingController manufacturingDateController =
//       TextEditingController();
//
//   bool _isLoading = false;
//
//   @override
//   void dispose() {
//     medicianNameController.dispose();
//     medicianCodeController.dispose();
//     stockController.dispose();
//     amountController.dispose();
//     expiryDateController.dispose();
//     manufacturingDateController.dispose();
//     super.dispose();
//   }
//
//   void _clearForm() {
//     medicianNameController.clear();
//     medicianCodeController.clear();
//     stockController.clear();
//     amountController.clear();
//     expiryDateController.clear();
//     manufacturingDateController.clear();
//   }
//
//   Future<void> _pickDate(TextEditingController controller) async {
//     final pickedDate = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(2000),
//       lastDate: DateTime(2100),
//     );
//     if (pickedDate != null) {
//       controller.text = DateFormat('yyyy-MM-dd').format(pickedDate);
//     }
//   }
//
//   void _saveMedician() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     setState(() => _isLoading = true);
//
//     try {
//       final hospitalId = await secureStorage.read(key: 'hospitalId');
//
//       final medicianData = {
//         "hospital_Id": int.parse(hospitalId!),
//         "medicianName": medicianNameController.text.trim(),
//         "medicianCode": medicianCodeController.text.trim(),
//         "stock": int.parse(stockController.text.trim()),
//         "amount": double.parse(amountController.text.trim()),
//         "expiryDate": expiryDateController.text.trim(),
//         "manifacturingDate": manufacturingDateController.text.trim(),
//       };
//
//       final result = await MedicineService().createMedician(medicianData);
//
//       if (result['status'] == 'success') {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(result['message'] ?? "Medician successfully added!"),
//             backgroundColor: Colors.green,
//           ),
//         );
//         _formKey.currentState!.reset();
//         _clearForm(); // ✅ clear inputs after save
//       } else {
//         throw result['error'];
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     const Color gold = Color(0xFFBF955E);
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F8F8),
//       appBar: _buildAppBar(gold),
//
//       /// 🔹 BODY WITH TABS
//       body: IndexedStack(
//         index: _currentIndex,
//         children: [
//           _buildAddMedicineUI(gold), // Add (your existing UI)
//           const Center(child: Text("Modify Medicine")),
//           const Center(child: Text("Expiry Medicines")),
//         ],
//       ),
//
//       /// 🔹 BOTTOM TAB BAR
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _currentIndex,
//         selectedItemColor: gold,
//         onTap: (index) => setState(() => _currentIndex = index),
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.add_circle_outline),
//             label: "Add",
//           ),
//           BottomNavigationBarItem(icon: Icon(Icons.edit), label: "Modify"),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.warning_amber),
//             label: "Expiry",
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// 🔹 YOUR ORIGINAL APP BAR (UNCHANGED)
//   PreferredSizeWidget _buildAppBar(Color gold) {
//     return PreferredSize(
//       preferredSize: const Size.fromHeight(100),
//       child: Container(
//         height: 100,
//         decoration: BoxDecoration(
//           color: gold,
//           borderRadius: const BorderRadius.only(
//             bottomLeft: Radius.circular(16),
//             bottomRight: Radius.circular(16),
//           ),
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             child: Row(
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//                   onPressed: () => Navigator.pop(context),
//                 ),
//                 const Text(
//                   "Add Medicine",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const Spacer(),
//                 IconButton(
//                   icon: const Icon(Icons.notifications, color: Colors.white),
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => const NotificationPage(),
//                       ),
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   /// 🔹 YOUR ORIGINAL ADD UI (UNCHANGED)
//   Widget _buildAddMedicineUI(Color gold) {
//     return Center(
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(15),
//         child: Container(
//           width: 500,
//           padding: const EdgeInsets.all(18),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(20),
//             boxShadow: const [
//               BoxShadow(
//                 color: Colors.black12,
//                 blurRadius: 10,
//                 offset: Offset(0, 4),
//               ),
//             ],
//           ),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 const SizedBox(height: 15),
//                 _buildTextField(
//                   controller: medicianNameController,
//                   label: "Medician Name *",
//                   icon: Icons.local_hospital_outlined,
//                   color: gold,
//                 ),
//                 const SizedBox(height: 16),
//                 _buildTextField(
//                   controller: medicianCodeController,
//                   label: "Medician Code (optional)",
//                   icon: Icons.qr_code_2_outlined,
//                   color: gold,
//                 ),
//                 const SizedBox(height: 16),
//                 _buildTextField(
//                   controller: stockController,
//                   label: "Stock Quantity *",
//                   icon: Icons.inventory_2_outlined,
//                   keyboardType: TextInputType.number,
//                   color: gold,
//                 ),
//                 const SizedBox(height: 16),
//                 _buildTextField(
//                   controller: amountController,
//                   label: "Amount (₹) *",
//                   icon: Icons.currency_rupee,
//                   keyboardType: TextInputType.number,
//                   color: gold,
//                 ),
//                 const SizedBox(height: 16),
//                 _buildDateField(
//                   controller: manufacturingDateController,
//                   label: "Manufacturing Date *",
//                   icon: Icons.calendar_today,
//                   color: gold,
//                 ),
//                 const SizedBox(height: 16),
//                 _buildDateField(
//                   controller: expiryDateController,
//                   label: "Expiry Date *",
//                   icon: Icons.event,
//                   color: gold,
//                 ),
//                 const SizedBox(height: 30),
//                 ElevatedButton(
//                   onPressed: _isLoading ? null : _saveMedician,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: gold,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                   ),
//                   child: _isLoading
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Text(
//                           "Save Medician",
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 18,
//                           ),
//                         ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   /// 🔹 FIELD HELPERS (UNCHANGED)
//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     required Color color,
//     TextInputType keyboardType = TextInputType.text,
//   }) {
//     return TextFormField(
//       controller: controller,
//       keyboardType: keyboardType,
//       decoration: InputDecoration(
//         labelText: label,
//         labelStyle: TextStyle(color: color),
//         prefixIcon: Icon(icon, color: color),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//       ),
//       validator: (val) {
//         if (label.contains("*") && (val == null || val.isEmpty)) {
//           return "Required field";
//         }
//         return null;
//       },
//     );
//   }
//
//   Widget _buildDateField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     required Color color,
//   }) {
//     return TextFormField(
//       controller: controller,
//       readOnly: true,
//       onTap: () => _pickDate(controller),
//       decoration: InputDecoration(
//         labelText: label,
//         labelStyle: TextStyle(color: color),
//         prefixIcon: Icon(icon, color: color),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//       ),
//       validator: (val) {
//         if (label.contains("*") && (val == null || val.isEmpty)) {
//           return "Required field";
//         }
//         return null;
//       },
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// lidator: (val) {
//         if (label.contains("*") && (val == null || val.isEmpty)) {
//           return "Required field";
//         }
//         return null;
//       },
//     );
//   }
// }

import '../../../../Services/Medicine_Service.dart';

class AddMedicianPage extends StatefulWidget {
  const AddMedicianPage({super.key});

  @override
  State<AddMedicianPage> createState() => _AddMedicianPageState();
}

class _AddMedicianPageState extends State<AddMedicianPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController medicianNameController = TextEditingController();
  final TextEditingController medicianCodeController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController manufacturingDateController =
      TextEditingController();

  bool _isLoading = false;
  static const Color gold = Color(0xFFBF955E);

  @override
  void dispose() {
    medicianNameController.dispose();
    medicianCodeController.dispose();
    stockController.dispose();
    amountController.dispose();
    expiryDateController.dispose();
    manufacturingDateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(pickedDate);
    }
  }

  Future<void> _saveMedician() async {
    if (_areFieldsEmpty()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("All fields are empty now."),
          backgroundColor: Colors.blueGrey,
        ),
      );
    }
    if (!_formKey.currentState!.validate()) return;
    // If all fields are empty, show message

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final hospitalId = prefs.getString('hospitalId');
      await MedicineService().createMedician({
        "hospital_Id": int.parse(hospitalId!),
        "medicianName": medicianNameController.text,
        "medicianCode": medicianCodeController.text,
        "stock": int.parse(stockController.text),
        "amount": double.parse(amountController.text),
        "expiryDate": expiryDateController.text,
        "manifacturingDate": manufacturingDateController.text,
      });

      // Clear all fields after save
      medicianNameController.clear();
      medicianCodeController.clear();
      stockController.clear();
      amountController.clear();
      expiryDateController.clear();
      manufacturingDateController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Medicine added successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _areFieldsEmpty() {
    return medicianNameController.text.isEmpty &&
        medicianCodeController.text.isEmpty &&
        stockController.text.isEmpty &&
        amountController.text.isEmpty &&
        expiryDateController.text.isEmpty &&
        manufacturingDateController.text.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _field(medicianNameController, "Medicine Name *"),
                    _field(medicianCodeController, "Medicine Code"),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            stockController,
                            "Stock *",
                            type: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(
                            amountController,
                            "Amount *",
                            type: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _dateField(
                            manufacturingDateController,
                            "Manufacturing Date *",
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _dateField(
                            expiryDateController,
                            "Expiry Date *",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveMedician,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Save Medicine",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        validator: (v) =>
            label.contains("*") && (v == null || v.isEmpty) ? "Required" : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: gold, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _dateField(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        readOnly: true,
        onTap: () => _pickDate(c),
        validator: (v) =>
            label.contains("*") && (v == null || v.isEmpty) ? "Required" : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          suffixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: gold, width: 1.5),
          ),
        ),
      ),
    );
  }
}
