import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Services/Medicine_Service.dart';

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
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFBF955E)),
        ),
        child: child!,
      ),
    );
    if (pickedDate != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(pickedDate);
    }
  }

  void _saveMedician() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true); // 🔹 show loading

    try {
      final prefs = await SharedPreferences.getInstance();
      final hospitalId = prefs.getString('hospitalId');
      final medicianData = {
        "hospital_Id": int.parse(hospitalId!),
        "medicianName": medicianNameController.text.trim(),
        "medicianCode": medicianCodeController.text.trim(),
        "stock": int.tryParse(stockController.text.trim()),
        "amount": double.tryParse(amountController.text.trim()),
        "expiryDate": expiryDateController.text.trim(),
        "manifacturingDate": manufacturingDateController.text.trim(),
      };

      final result = await MedicineService().createMedician(medicianData);

      if (result['status'] == 'success' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? "Medician successfully added!"),
            backgroundColor: Colors.green,
          ),
        );
        _formKey.currentState!.reset();
        dispose();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? "Failed to add medician"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false); // 🔹 hide loading
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFBF955E);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // const Icon(
                  //   Icons.medical_services_outlined,
                  //   size: 60,
                  //   color: gold,
                  // ),
                  // const SizedBox(height: 10),
                  // const Text(
                  //   "Medician Information",
                  //   textAlign: TextAlign.center,
                  //   style: TextStyle(
                  //     color: gold,
                  //     fontWeight: FontWeight.bold,
                  //     fontSize: 24,
                  //     letterSpacing: 1,
                  //   ),
                  // ),
                  const SizedBox(height: 15),

                  // Medician Name
                  _buildTextField(
                    controller: medicianNameController,
                    label: "Medician Name *",
                    icon: Icons.local_hospital_outlined,
                    color: gold,
                  ),
                  const SizedBox(height: 16),

                  // Medician Code
                  _buildTextField(
                    controller: medicianCodeController,
                    label: "Medician Code (optional)",
                    icon: Icons.qr_code_2_outlined,
                    color: gold,
                  ),
                  const SizedBox(height: 16),

                  // Stock
                  _buildTextField(
                    controller: stockController,
                    label: "Stock Quantity *",
                    icon: Icons.inventory_2_outlined,
                    keyboardType: TextInputType.number,
                    color: gold,
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  _buildTextField(
                    controller: amountController,
                    label: "Amount (₹) *",
                    icon: Icons.currency_rupee,
                    keyboardType: TextInputType.number,
                    color: gold,
                  ),
                  const SizedBox(height: 16),

                  // Manufacturing Date
                  _buildDateField(
                    controller: manufacturingDateController,
                    label: "Manufacturing Date *",
                    icon: Icons.calendar_today,
                    color: gold,
                  ),
                  const SizedBox(height: 16),

                  // Expiry Date
                  _buildDateField(
                    controller: expiryDateController,
                    label: "Expiry Date *",
                    icon: Icons.event,
                    color: gold,
                  ),
                  const SizedBox(height: 30),

                  // Save Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveMedician,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 5,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Save Medician",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: color),
        prefixIcon: Icon(icon, color: color),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (val) {
        if (label.contains("*") && (val == null || val.isEmpty)) {
          return "Required field";
        }
        return null;
      },
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: color),
        prefixIcon: Icon(icon, color: color),
        suffixIcon: IconButton(
          icon: const Icon(Icons.date_range, color: Colors.grey),
          onPressed: () => _pickDate(controller),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (val) {
        if (label.contains("*") && (val == null || val.isEmpty)) {
          return "Required field";
        }
        return null;
      },
    );
  }
}
