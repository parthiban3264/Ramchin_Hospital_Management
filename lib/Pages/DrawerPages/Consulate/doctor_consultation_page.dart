import 'package:flutter/material.dart';
import 'package:hospitrax/Services/testing&scanning_service.dart';
import 'package:hospitrax/Services/treatment_service.dart';
import 'package:intl/intl.dart';
import '../../../Services/Doctor/doctor_service.dart';
import '../../../Services/Medicine&Injection_service.dart';
import '../../../Services/consultation_service.dart';
import '../../NotificationsPage.dart';
import 'treatment_section.dart';
import 'medicine_injection_section.dart';
import 'testing_scanning_section.dart';

const Color primaryColor = Color(0xFFBF955E);

class DoctorConsultationPage extends StatefulWidget {
  final Map<String, dynamic> consultation;
  const DoctorConsultationPage({super.key, required this.consultation});

  @override
  State<DoctorConsultationPage> createState() => _DoctorConsultationPageState();
}

class _DoctorConsultationPageState extends State<DoctorConsultationPage> {
  final _formKey = GlobalKey<FormState>();
  final ConsultationService _service = ConsultationService();
  final DoctorService _staffService = DoctorService();
  final TreatmentService _treatmentService = TreatmentService();
  final TestingScanningService _testingScanningService =
      TestingScanningService();
  final MedicineInjectionService _medicineInjectionService =
      MedicineInjectionService();

  late TextEditingController _diagnosisController;
  late TextEditingController _notesController;
  late TextEditingController _treatmentTitleController;
  late TextEditingController _treatmentNotesController;

  // Medicine controllers
  late TextEditingController _medicineNameController;
  late TextEditingController _medicineNotesController;
  late TextEditingController _medicineFrequencyController;
  late TextEditingController _medicineDosageController;
  late TextEditingController _medicineDurationController;

  // Injection controllers
  late TextEditingController _injectionNameController;
  late TextEditingController _injectionNotesController;
  late TextEditingController _injectionFrequencyController;
  late TextEditingController _injectionDosageController;
  late TextEditingController _injectionDurationController;

  // Testing/Scanning controller
  late TextEditingController _testingTitleController;

  bool _treatmentEnabled = false;

  // bool _medicineEnabled = false;
  // bool _injectionEnabled = false;
  bool _medInjEnabled = false;
  bool _testingEnabled = false;
  bool _isSaving = false;

  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _scheduleDate;

  List<Map<String, dynamic>> _staffList = [];
  Set<String> _selectedStaffIds = {};

  List<Map<String, dynamic>> _medicines = [];
  List<Map<String, dynamic>> _injections = [];

  @override
  void initState() {
    super.initState();
    final c = widget.consultation;

    _diagnosisController = TextEditingController(text: c['diagnosis'] ?? '');
    _notesController = TextEditingController(text: c['notes'] ?? '');
    _treatmentTitleController = TextEditingController();
    _treatmentNotesController = TextEditingController();

    _medicineNameController = TextEditingController();
    _medicineNotesController = TextEditingController();
    _medicineFrequencyController = TextEditingController();
    _medicineDosageController = TextEditingController();
    _medicineDurationController = TextEditingController();

    _injectionNameController = TextEditingController();
    _injectionNotesController = TextEditingController();
    _injectionFrequencyController = TextEditingController();
    _injectionDosageController = TextEditingController();
    _injectionDurationController = TextEditingController();

    _testingTitleController = TextEditingController();

    _fetchStaffList();
  }

  Future<void> _fetchStaffList() async {
    final staff = await _staffService.getStaffs();
    setState(() {
      _staffList = staff;
    });
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart)
          _startDate = picked;
        else
          _endDate = picked;
      });
    }
  }

  Future<void> _pickScheduleDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _scheduleDate = picked;
      });
    }
  }

  Future<void> _saveConsultation() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final dynamic hospitalIdRaw = widget.consultation['hospital_Id'];
      final int hospitalId = (hospitalIdRaw is int)
          ? hospitalIdRaw
          : int.tryParse(hospitalIdRaw.toString()) ?? 0;

      final String doctorId = widget.consultation['doctor_Id'].toString();
      final String patientId = widget.consultation['patient_Id'].toString();
      final int consultationId = widget.consultation['id'];

      // Save sections individually
      if (_treatmentEnabled) {
        await _treatmentService.createTreatment({
          "hospital_Id": hospitalId,
          "patient_Id": patientId,
          "doctor_Id": doctorId,
          "staff_Id": _selectedStaffIds.toList(),
          "treatmentName": [_treatmentTitleController.text],
          "treatmentNotes": {"text": _treatmentNotesController.text},
          "startDate":
              _startDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
          "endDate":
              _endDate?.toIso8601String() ??
              DateTime.now().add(const Duration(days: 7)).toIso8601String(),
          "progress": "Not started",
          "paymentStatus": false,
        });
      }

      if (_medInjEnabled) {
        await _medicineInjectionService.createMedicineInjection({
          "hospital_Id": hospitalId,
          "patient_Id": patientId,
          "doctor_Id": [doctorId],
          "staff_Id": _selectedStaffIds.toList(),
          "medicine_Id": _medicines.map((e) => e['name']).toList(),
          "dosageMedicine": _medicines.map((e) => e['dosage']).toList(),
          "medicineNotes": _medicines.map((e) => e['notes']).toList(),
          "frequencyMedicine": _medicines.map((e) => e['frequency']).toList(),
          "durationMedicine": _medicines.isNotEmpty
              ? _medicines.last['duration'] ?? ''
              : '',
          "injection_Id": _injections.map((e) => e['name']).toList(),
          "dosageInjection": _injections.map((e) => e['dosage']).toList(),
          "InjectionNotes": _injections.map((e) => e['notes']).toList(),
          "frequencyInjection": _injections.map((e) => e['frequency']).toList(),
          "durationInjection": _injections.isNotEmpty
              ? _injections.last['duration'] ?? ''
              : '',
          "medicineStatus": _medicines.isNotEmpty,
          "injectionStatus": _injections.isNotEmpty,
          "paymentStatus": false,
        });
      }

      if (_testingEnabled) {
        await _testingScanningService.createTestingScanning({
          "hospital_Id": hospitalId,
          "patient_Id": patientId,
          "doctor_Id": [doctorId],
          "staff_Id": _selectedStaffIds.isEmpty
              ? null
              : _selectedStaffIds.toList(),
          "title": _testingTitleController.text.isEmpty
              ? "Ordered by Doctor"
              : _testingTitleController.text,
          "scheduleDate":
              _scheduleDate?.toIso8601String() ??
              DateTime.now().toIso8601String(),
          "type": "Scanning / Testing",
          "paymentStatus": false,
          "result": "",
        });
      }

      // ✅ Update consultation status only once
      if (_treatmentEnabled || _medInjEnabled || _testingEnabled) {
        await _service.updateConsultation(consultationId, {
          "treatment": _treatmentEnabled,
          "medicineInjection": _medInjEnabled,
          "scanningTesting": _testingEnabled,
          "status": "COMPLETED",
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Consultation & Orders saved successfully'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error saving: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.consultation;
    final appointDate = DateTime.tryParse(c['appointdate']?.toString() ?? '');
    final formattedTime = appointDate != null
        ? DateFormat('MMM dd, yyyy • hh:mm a').format(appointDate)
        : '-';

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 100,
          decoration: const BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
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
                  const Text(
                    'Consultation Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Patient info
                  _buildProfileCard(c, formattedTime),
                  const SizedBox(height: 16),
                  _buildTextField('Diagnosis', _diagnosisController),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'General Notes',
                    _notesController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  // Treatment
                  TreatmentSection(
                    enabled: _treatmentEnabled,
                    onToggle: (v) => setState(() => _treatmentEnabled = v),
                    titleController: _treatmentTitleController,
                    notesController: _treatmentNotesController,
                    startDate: _startDate,
                    endDate: _endDate,
                    pickDate: _pickDate,
                    staffList: _staffList,
                    selectedStaffIds: _selectedStaffIds,
                  ),
                  // Medicine/Injection
                  MedicineInjectionSection(
                    enabled:
                        _medInjEnabled, // single boolean for both medicine & injection
                    onToggle: (v) => setState(() => _medInjEnabled = v),
                    medicines: _medicines,
                    injections: _injections,
                    addMedicine: (m) => setState(() => _medicines.add(m)),
                    addInjection: (i) => setState(() => _injections.add(i)),
                    medicineNameController: _medicineNameController,
                    medicineNotesController: _medicineNotesController,
                    medicineFrequencyController: _medicineFrequencyController,
                    medicineDosageController: _medicineDosageController,
                    medicineDurationController: _medicineDurationController,
                    injectionNameController: _injectionNameController,
                    injectionNotesController: _injectionNotesController,
                    injectionFrequencyController: _injectionFrequencyController,
                    injectionDosageController: _injectionDosageController,
                    injectionDurationController: _injectionDurationController,
                  ),

                  // Testing/Scanning
                  TestingScanningSection(
                    enabled: _testingEnabled,
                    onToggle: (v) => setState(() => _testingEnabled = v),
                    titleController: _testingTitleController,
                    scheduleDate: _scheduleDate,
                    pickDate: _pickScheduleDate,
                    staffList: _staffList,
                    selectedStaffIds: _selectedStaffIds,
                    onStaffChanged: (newSet) =>
                        setState(() => _selectedStaffIds = newSet),
                  ),

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveConsultation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 32,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Consultation & Orders',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black38,
              child: const Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> c, String formattedTime) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "🧑 Patient: ${c['patientName'] ?? '-'}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow("Patient ID", c['patient_Id']),
            _buildInfoRow("Doctor", c['doctorName']),
            _buildInfoRow("Doctor ID", c['doctor_Id']),
            _buildInfoRow("Hospital", c['hospitalName']),
            _buildInfoRow("Hospital ID", c['hospital_Id']),
            _buildInfoRow("Purpose", c['purpose']),
            _buildInfoRow("Gender", c['gender']),
            _buildInfoRow("DOB", c['dob']),
            _buildInfoRow("Appointment", formattedTime),
            _buildInfoRow("Blood Type", c['bldGrp']),
            _buildInfoRow("BP", c['bp']),
            _buildInfoRow("Sugar", c['sugar']),
            _buildInfoRow("Height", "${c['height']} cm"),
            _buildInfoRow("Weight", "${c['weight']} kg"),
            _buildInfoRow("Medical History", c['medicalHistory']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value?.toString() ?? '-',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Please enter $label' : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor),
        ),
      ),
    );
  }
}
