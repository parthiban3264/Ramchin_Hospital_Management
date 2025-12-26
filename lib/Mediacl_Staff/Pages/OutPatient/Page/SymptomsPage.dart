import 'package:flutter/material.dart';
import '../../../../Pages/NotificationsPage.dart';
import '../../../../Services/consultation_service.dart';
import '../../../../Services/patient_service.dart';

class SymptomsPage extends StatefulWidget {
  final Map<String, dynamic> patient;
  final int consultationId;

  const SymptomsPage({
    Key? key,
    required this.patient,
    required this.consultationId,
  }) : super(key: key);

  @override
  _SymptomsPageState createState() => _SymptomsPageState();
}

class _SymptomsPageState extends State<SymptomsPage> {
  final patientService = PatientService();

  final weightController = TextEditingController();
  final heightController = TextEditingController();
  final bpController = TextEditingController();
  final tempController = TextEditingController();
  final bgroupController = TextEditingController();
  final sugarController = TextEditingController();
  final TextEditingController systolicController = TextEditingController();
  final TextEditingController diastolicController = TextEditingController();

  String? selectedBP;
  String? selectedSugar;
  String? selectedBloodGroup;

  bool showBPOptions = false;
  bool showSugarOptions = false;
  bool showBloodGroupOptions = false;
  bool isSubmitting = false;

  final Color primaryColor = const Color(0xFFBF955E);

  String get formattedBP {
    final sys = systolicController.text.trim();
    final dia = diastolicController.text.trim();
    if (sys.isEmpty || dia.isEmpty) return '';
    return '$sys / $dia mmHg';
  }

  bool get isAnyFieldFilled {
    return weightController.text.trim().isNotEmpty ||
        heightController.text.trim().isNotEmpty ||
        tempController.text.trim().isNotEmpty ||
        systolicController.text.trim().isNotEmpty ||
        diastolicController.text.trim().isNotEmpty ||
        sugarController.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();

    weightController.addListener(_onFieldChange);
    heightController.addListener(_onFieldChange);
    tempController.addListener(_onFieldChange);
    systolicController.addListener(_onFieldChange);
    diastolicController.addListener(_onFieldChange);
    sugarController.addListener(_onFieldChange);
  }

  void _onFieldChange() {
    setState(() {});
  }

  Future<void> _submitPatient() async {
    final missingFields = <String>[];

    // Check if all fields are empty
    final allEmpty = [
      weightController.text.trim(),
      heightController.text.trim(),
      tempController.text.trim(),
      bpController.text.trim(),
      sugarController.text.trim(),
      (selectedBloodGroup ?? "").trim(),
    ].every((field) => field.isEmpty);

    if (allEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please fill at least one"),
          backgroundColor: Colors.red.shade400,
        ),
      );
      return;
    }

    setState(() => isSubmitting = true);
    try {
      // final userId = widget.patient["user_Id"].toString();
      // print(userId);
      // final result = await patientService.updatePatient(userId, {
      //   "height": int.tryParse(heightController.text) ?? 0,
      //   "weight": int.tryParse(weightController.text) ?? 0,
      //   "bp": bpController.text ?? "",
      //   "sugar": sugarController.text ?? "",
      //   "bldGrp": selectedBloodGroup ?? "",
      //   "temperature": int.tryParse(tempController.text) ?? 0,
      // });
      final Id = widget.consultationId;

      print('vvvcc${widget.patient}');
      print(Id);
      final UpdateResult = await ConsultationService().updateConsultation(Id, {
        "symptoms": true,
        "height": int.tryParse(heightController.text) ?? 0,
        "weight": int.tryParse(weightController.text) ?? 0,
        "bp": bpController.text ?? "",
        "sugar": sugarController.text ?? "",
        "temperature": int.tryParse(tempController.text) ?? 0,
      });
      print(UpdateResult);
      if (UpdateResult['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("✅ Vitals saved successfully"),
            backgroundColor: primaryColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed saving Vitals"),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
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
                    "Vitals Entry",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // IconButton(
                  //   icon: const Icon(Icons.notifications, color: Colors.white),
                  //   onPressed: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (_) => const NotificationPage(),
                  //       ),
                  //     );
                  //   },
                  // ),
                  IconButton(
                    icon: const Icon(Icons.home, color: Colors.white),
                    onPressed: () {
                      int count = 0;
                      Navigator.popUntil(context, (route) => count++ >= 2);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputField(
              'Weight (kg)',
              weightController,
              Icons.monitor_weight,
              TextInputType.number,
            ),
            _buildInputField(
              'Height (cm)',
              heightController,
              Icons.height,
              TextInputType.number,
            ),
            _buildInputField(
              'Temperature (°F)',
              tempController,
              Icons.thermostat,
              TextInputType.number,
            ),
            // --- Blood Pressure Section ---
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: Colors.black26,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.favorite_border, color: primaryColor),
                          const SizedBox(width: 10),
                          Text(
                            "Blood Pressure (mmHg)",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Systolic Input
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: systolicController,
                              cursorColor: primaryColor,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'SYS',
                                labelStyle: TextStyle(color: Colors.black),
                                hintText: '120',
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 10,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: primaryColor,
                                    width: 2,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onChanged: (_) {
                                bpController.text = formattedBP;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '/',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Diastolic Input
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: diastolicController,
                              cursorColor: primaryColor,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'DIA',
                                labelStyle: TextStyle(color: Colors.black),
                                hintText: '80',
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 10,
                                ),

                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: primaryColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                              onChanged: (_) {
                                bpController.text = formattedBP;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'mmHg',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Sugar Section
            // --- Sugar Level Section ---
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: Colors.black26,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.opacity, color: primaryColor),
                          const SizedBox(width: 10),
                          Text(
                            "Sugar Level (mg/dL)",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        cursorColor: primaryColor,
                        controller: sugarController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Enter Sugar Level',
                          labelStyle: TextStyle(color: Colors.black),
                          hintText: 'e.g. 110',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 14,
                          ),

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // // Blood Group Section
            // _buildInteractiveInput(
            //   'Select Blood Group',
            //   bgroupController,
            //   Icons.bloodtype,
            //   () => setState(() {
            //     showBloodGroupOptions = !showBloodGroupOptions;
            //     showBPOptions = false;
            //     showSugarOptions = false;
            //   }),
            // ),
            // AnimatedSwitcher(
            //   duration: const Duration(milliseconds: 300),
            //   child: showBloodGroupOptions
            //       ? Padding(
            //           padding: const EdgeInsets.only(top: 10, bottom: 20),
            //           child: _buildHorizontalSelector(
            //             ['A+', 'A−', 'B+', 'B−', 'AB+', 'AB−', 'O+', 'O−'],
            //             selectedBloodGroup,
            //             (val) {
            //               setState(() {
            //                 selectedBloodGroup = val;
            //                 bgroupController.text = val;
            //               });
            //             },
            //             height: 60,
            //           ),
            //         )
            //       : const SizedBox.shrink(),
            // ),
            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                //onPressed: isSubmitting ? null : _submitPatient,
                onPressed: (!isAnyFieldFilled || isSubmitting)
                    ? null
                    : _submitPatient,

                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 6,
                ),
                child: isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Vitals',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Reusable Widgets ---

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    IconData icon,
    TextInputType type,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: TextField(
        cursorColor: primaryColor,
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: primaryColor),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black87),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
        ),
      ),
    );
  }

  Widget buildBPInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 🔹 Systolic Input (Top number)
        SizedBox(
          width: 80,
          child: TextField(
            controller: systolicController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'SYS',
              hintText: '120',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 10,
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),
        const Text(
          '/',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),

        // 🔹 Diastolic Input (Bottom number)
        SizedBox(
          width: 80,
          child: TextField(
            controller: diastolicController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'DIA',
              hintText: '80',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 10,
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),
        const Text(
          'mmHg',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildInteractiveInput(
    String label,
    TextEditingController controller,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: _buildInputField(label, controller, icon, TextInputType.text),
      ),
    );
  }

  Widget _buildCategoryTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }

  Widget _buildHorizontalSelector(
    List<String> options,
    String? selectedOption,
    Function(String) onSelect, {
    double height = 50,
  }) {
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = selectedOption == option;
          return GestureDetector(
            onTap: () => onSelect(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withOpacity(0.1)
                    : Colors.white,
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.grey.shade300,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              alignment: Alignment.center,
              child: Text(
                option,
                style: TextStyle(
                  color: isSelected ? primaryColor : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
