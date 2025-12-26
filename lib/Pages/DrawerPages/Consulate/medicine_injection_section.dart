import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFFBF955E);

class MedicineInjectionSection extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final List<Map<String, dynamic>> medicines;
  final List<Map<String, dynamic>> injections;
  final void Function(Map<String, dynamic>) addMedicine;
  final void Function(Map<String, dynamic>) addInjection;

  // Medicine controllers
  final TextEditingController medicineNameController;
  final TextEditingController medicineNotesController;
  final TextEditingController medicineFrequencyController;
  final TextEditingController medicineDosageController;
  final TextEditingController medicineDurationController;

  // Injection controllers
  final TextEditingController injectionNameController;
  final TextEditingController injectionNotesController;
  final TextEditingController injectionFrequencyController;
  final TextEditingController injectionDosageController;
  final TextEditingController injectionDurationController;

  const MedicineInjectionSection({
    super.key,
    required this.enabled,
    required this.onToggle,
    required this.medicines,
    required this.injections,
    required this.addMedicine,
    required this.addInjection,
    required this.medicineNameController,
    required this.medicineNotesController,
    required this.medicineFrequencyController,
    required this.medicineDosageController,
    required this.medicineDurationController,
    required this.injectionNameController,
    required this.injectionNotesController,
    required this.injectionFrequencyController,
    required this.injectionDosageController,
    required this.injectionDurationController,
  });

  /// ✅ Use this method before saving the consultation
  /// to make sure pending text fields are added automatically.
  Map<String, List<Map<String, dynamic>>> saveSection() {
    // Automatically add any unsaved medicine
    if (medicineNameController.text.isNotEmpty) {
      addMedicine({
        "name": medicineNameController.text,
        "notes": medicineNotesController.text,
        "frequency": medicineFrequencyController.text,
        "dosage": medicineDosageController.text,
        "duration": medicineDurationController.text,
        "status": false,
      });
      medicineNameController.clear();
      medicineNotesController.clear();
      medicineFrequencyController.clear();
      medicineDosageController.clear();
      medicineDurationController.clear();
    }

    // Automatically add any unsaved injection
    if (injectionNameController.text.isNotEmpty) {
      addInjection({
        "name": injectionNameController.text,
        "notes": injectionNotesController.text,
        "frequency": injectionFrequencyController.text,
        "dosage": injectionDosageController.text,
        "duration": injectionDurationController.text,
        "status": false,
      });
      injectionNameController.clear();
      injectionNotesController.clear();
      injectionFrequencyController.clear();
      injectionDosageController.clear();
      injectionDurationController.clear();
    }

    return {"medicines": medicines, "injections": injections};
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSectionHeader("Medicine & Injection", enabled, onToggle),
        if (enabled) _buildForms(context),
        if (enabled && medicines.isNotEmpty)
          _buildRecommendationsList("Medicine", medicines),
        if (enabled && injections.isNotEmpty)
          _buildRecommendationsList("Injection", injections),
      ],
    );
  }

  Widget _buildSectionHeader(
    String title,
    bool enabled,
    ValueChanged<bool> onToggle,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Spacer(),
            Switch(
              value: enabled,
              onChanged: onToggle,
              activeColor: primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForms(BuildContext context) {
    return _buildFormCard(
      children: [
        // --- Medicine Form ---
        const Text(
          "Medicine",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 6),
        _buildTextField("Name", medicineNameController),
        _buildTextField("Notes", medicineNotesController),
        Row(
          children: [
            Expanded(
              child: _buildTextField("Frequency", medicineFrequencyController),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField("Dosage", medicineDosageController),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField("Duration", medicineDurationController),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text("Add Medicine"),
          onPressed: () {
            if (medicineNameController.text.isEmpty) return;
            addMedicine({
              "name": medicineNameController.text,
              "notes": medicineNotesController.text,
              "frequency": medicineFrequencyController.text,
              "dosage": medicineDosageController.text,
              "duration": medicineDurationController.text,
              "status": false,
            });
            medicineNameController.clear();
            medicineNotesController.clear();
            medicineFrequencyController.clear();
            medicineDosageController.clear();
            medicineDurationController.clear();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const Divider(height: 24),

        // --- Injection Form ---
        const Text(
          "Injection",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 6),
        _buildTextField("Name", injectionNameController),
        _buildTextField("Notes", injectionNotesController),
        Row(
          children: [
            Expanded(
              child: _buildTextField("Frequency", injectionFrequencyController),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField("Dosage", injectionDosageController),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField("Duration", injectionDurationController),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text("Add Injection"),
          onPressed: () {
            if (injectionNameController.text.isEmpty) return;
            addInjection({
              "name": injectionNameController.text,
              "notes": injectionNotesController.text,
              "frequency": injectionFrequencyController.text,
              "dosage": injectionDosageController.text,
              "duration": injectionDurationController.text,
              "status": false,
            });
            injectionNameController.clear();
            injectionNotesController.clear();
            injectionFrequencyController.clear();
            injectionDosageController.clear();
            injectionDurationController.clear();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsList(
    String type,
    List<Map<String, dynamic>> items,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: Text("$type: ${item['name'] ?? ''}"),
            subtitle: Text(
              "Dosage: ${item['dosage'] ?? '-'} | "
              "Frequency: ${item['frequency'] ?? '-'} | "
              "Duration: ${item['duration'] ?? '-'}",
            ),
            trailing: item['notes'] != null && item['notes'] != ''
                ? Icon(Icons.info_outline, color: primaryColor)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildFormCard({required List<Widget> children}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: children
              .map(
                (w) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: w,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: primaryColor),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
