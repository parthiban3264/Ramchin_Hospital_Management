import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Pages/NotificationsPage.dart';
import '../../../Services/Injection_Service.dart';

class AddInjectionPage extends StatefulWidget {
  const AddInjectionPage({super.key});

  @override
  State<AddInjectionPage> createState() => _AddInjectionPageState();
}

class _AddInjectionPageState extends State<AddInjectionPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController injectionNameController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();

  final TextEditingController injectionCodeController = TextEditingController();

  final TextEditingController manufacturingDateController =
      TextEditingController();

  bool _isLoading = false;

  List<Map<String, TextEditingController>> vialRows = [];

  @override
  void initState() {
    super.initState();
    _addVialRow();
  }

  @override
  void dispose() {
    injectionNameController.dispose();

    injectionCodeController.dispose();

    expiryDateController.dispose();
    manufacturingDateController.dispose();
    for (var row in vialRows) {
      row['vial']!.dispose();
      row['stock']!.dispose();
      row['price']!.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFBF955E)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  void _addVialRow() {
    setState(() {
      vialRows.add({
        'vial': TextEditingController(),
        'stock': TextEditingController(),
        'price': TextEditingController(),
      });
    });
  }

  void _removeVialRow(int index) {
    setState(() {
      vialRows[index]['vial']!.dispose();
      vialRows[index]['stock']!.dispose();
      vialRows[index]['price']!.dispose();
      vialRows.removeAt(index);
    });
  }

  Future<void> _saveInjection() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final hospitalId = prefs.getString('hospitalId');
      final Map<String, int> stockMap = {};
      final Map<String, double> amountMap = {};

      for (var row in vialRows) {
        final vial = row['vial']!.text.trim();
        if (vial.isEmpty) continue;
        stockMap[vial] = int.tryParse(row['stock']!.text.trim()) ?? 0;
        amountMap[vial] = double.tryParse(row['price']!.text.trim()) ?? 0.0;
      }

      final injectionData = {
        "hospital_Id": int.parse(hospitalId!),
        "injectionName": injectionNameController.text.trim(),

        'injectionCode': injectionCodeController.text.trim(),

        "stock": stockMap,
        "amount": amountMap,
        "expiryDate": expiryDateController.text.trim(),
        "manifacturingDate": manufacturingDateController.text.trim(),
      };

      final result = await InjectionService().createInjection(injectionData);

      if (result['status'] == 'success' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? "Injection added successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        _formKey.currentState!.reset();
        setState(() {
          vialRows.clear();
          _addVialRow();
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? "Failed to add injection"),
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
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFBF955E);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: gold,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
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
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    "Add Injection",
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _sectionHeader("Injection Information", gold),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: injectionNameController,
                    label: "Injection Name *",
                    icon: Icons.vaccines_outlined,
                    color: gold,
                  ),
                  const SizedBox(height: 18),

                  _buildTextField(
                    controller: injectionCodeController,
                    label: "Injection Code *",
                    icon: Icons.qr_code_sharp,
                    color: gold,
                  ),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          controller: manufacturingDateController,
                          label: "Manufacturing Date *",
                          icon: Icons.calendar_today,
                          color: gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          controller: expiryDateController,
                          label: "Expiry Date *",
                          icon: Icons.event,
                          color: gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Divider(color: Colors.grey.shade300, thickness: 1),
                  const SizedBox(height: 10),
                  _sectionHeader("Vial Details", gold),
                  const SizedBox(height: 10),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Column(children: _buildVialRows(gold)),
                  ),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _addVialRow,
                      icon: const Icon(Icons.add_circle_outline, color: gold),
                      label: const Text(
                        "Add Another Vial",
                        style: TextStyle(
                          color: gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveInjection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            "Save Injection",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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

  Widget _sectionHeader(String title, Color color) {
    return Row(
      children: [
        Icon(Icons.medical_services_outlined, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildVialRows(Color gold) {
    return List.generate(vialRows.length, (index) {
      final row = vialRows[index];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildSmallField(
                controller: row['vial']!,
                label: "Vial (e.g. 1mL)",
                color: gold,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _buildSmallField(
                controller: row['stock']!,
                label: "Stock",
                keyboardType: TextInputType.number,
                color: gold,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _buildSmallField(
                controller: row['price']!,
                label: "Price (₹)",
                keyboardType: TextInputType.number,
                color: gold,
              ),
            ),
            if (vialRows.length > 1)
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                onPressed: () => _removeVialRow(index),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: color),
        labelText: label,
        labelStyle: TextStyle(color: color),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (val) => label.contains("*") && (val == null || val.isEmpty)
          ? "Required"
          : null,
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
      onTap: () => _pickDate(controller),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: color),
        suffixIcon: const Icon(Icons.date_range, color: Colors.grey),
        labelText: label,
        labelStyle: TextStyle(color: color),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (val) => label.contains("*") && (val == null || val.isEmpty)
          ? "Required"
          : null,
    );
  }

  Widget _buildSmallField({
    required TextEditingController controller,
    required String label,
    required Color color,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: color),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 12,
        ),
      ),
      validator: (val) => (val == null || val.isEmpty) ? "Required" : null,
    );
  }
}
