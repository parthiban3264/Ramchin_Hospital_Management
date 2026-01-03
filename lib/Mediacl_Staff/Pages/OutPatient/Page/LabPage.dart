import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../Pages/NotificationsPage.dart';
import '../../../../Services/admin_service.dart';
import '../../../../Services/consultation_service.dart';
import '../../../../Services/socket_service.dart';
import '../../../../Services/testing&scanning_service.dart';
import '../Report/ReportCard.dart';

class LabPage extends StatefulWidget {
  final List<Map<String, dynamic>> allTests;
  final int currentIndex;
  final String queueStaus; // "COMPLETED" or "PENDING"
  final int mode; //  0 or 1

  const LabPage({
    super.key,
    required this.allTests,
    required this.currentIndex,
    required this.queueStaus,
    required this.mode,
  });

  @override
  State<LabPage> createState() => _LabPageState();
}

class _LabPageState extends State<LabPage> with SingleTickerProviderStateMixin {
  final Color primaryColor = const Color(0xFFBF955E);
  final socketService = SocketService();

  bool _isPatientExpanded = false;
  bool _isXrayExpanded = false;
  bool _isLoading = false;
  String? _dateTime;

  late AnimationController _patientController;
  late Animation<double> _patientExpandAnimation;

  final TextEditingController _descriptionController = TextEditingController();

  late List<bool> _completedList;
  late List<TextEditingController> _optionControllers;
  late List<String> _selectedOptions;

  String? logo;
  Color _genderColor(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return Colors.lightBlue.shade400;
      case 'female':
        return Colors.pink.shade300;
      default:
        return Colors.orange.shade400;
    }
  }

  IconData _genderIcon(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return Icons.male;
      case 'female':
        return Icons.female;
      default:
        return Icons.transgender;
    }
  }

  List<Map<String, dynamic>> get currentTestDetails {
    final record = widget.allTests[widget.currentIndex];
    final List<dynamic>? testDetails = record['testDetails'];
    if (testDetails == null || testDetails.isEmpty) return [];
    if (testDetails[0] is Map<String, dynamic>) {
      return List<Map<String, dynamic>>.from(testDetails);
    }
    return [];
  }

  Map<String, String> get optionReferenceMap {
    final record = widget.allTests[widget.currentIndex];
    final List<dynamic>? testDetails = record['testDetails'];

    if (testDetails != null && testDetails.isNotEmpty) {
      final options = testDetails[0]['options'] as List<dynamic>? ?? [];
      return {
        for (var opt in options)
          opt['name']?.toString() ?? '': opt['reference']?.toString() ?? '',
      };
    }
    return {};
  }

  List<String> get selectedOptionNames {
    final options = currentTestDetails.isNotEmpty
        ? currentTestDetails[0]['options']
        : null;
    if (options is List) {
      return options
          .whereType<Map<String, dynamic>>()
          .map((opt) => opt['selectedOption']?.toString() ?? '')
          .where((name) => name.isNotEmpty && name != 'N/A')
          .toList();
    }
    return [];
  }

  String _labName = '';

  @override
  void initState() {
    super.initState();
    _updateTime();

    _completedList = widget.allTests
        .map(
          (e) =>
              (e['queueStatus'] ?? '').toString().toUpperCase() == 'COMPLETED',
        )
        .toList();

    _patientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _patientExpandAnimation = CurvedAnimation(
      parent: _patientController,
      curve: Curves.easeInOut,
    );

    _selectedOptions = selectedOptionNames;

    _optionControllers = List.generate(_selectedOptions.length, (index) {
      final optionName = _selectedOptions[index];
      final savedText = savedOptionResults[optionName] ?? '';
      return TextEditingController(text: savedText);
    });

    final desc =
        widget.allTests[widget.currentIndex]['result']?.toString() ?? '';
    _descriptionController.text = desc;

    _loadHospitalLogo();

    _initLab();
  }

  void _loadHospitalLogo() async {
    final prefs = await SharedPreferences.getInstance();

    logo = prefs.getString('hospitalPhoto');
    setState(() {});
  }

  Future<void> _initLab() async {
    final prefs = await SharedPreferences.getInstance();

    final labId = prefs.getString('userId');
    if (labId != null) {
      await loadNames(labId);
    }
  }

  Future<void> loadNames(String userId) async {
    final labProfile = await AdminService().getLabProfile(userId);

    setState(() {
      _labName = labProfile?['name'] ?? '';
    });
  }

  @override
  void dispose() {
    _patientController.dispose();
    _descriptionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateTime() {
    setState(() {
      _dateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
    });
  }

  void _togglePatientExpand() {
    setState(() {
      _isPatientExpanded = !_isPatientExpanded;
      if (_isPatientExpanded) {
        _patientController.forward();
      } else {
        _patientController.reverse();
      }
    });
  }

  void _toggleXrayExpand() {
    setState(() {
      _isXrayExpanded = !_isXrayExpanded;
    });
  }

  String _formatDob(String? dob) {
    if (dob == null || dob.isEmpty) return 'N/A';
    try {
      return DateFormat('dd-MM-yyyy').format(DateTime.parse(dob));
    } catch (_) {
      return dob;
    }
  }

  String _calculateAge(String? dob) {
    if (dob == null || dob.isEmpty) return 'N/A';
    try {
      final birthDate = DateTime.parse(dob);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return "$age yrs";
    } catch (_) {
      return 'N/A';
    }
  }

  Future<void> _handleComplete() async {
    setState(() => _isLoading = true);
    try {
      final description = _descriptionController.text.trim();
      // if (description.isEmpty) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //       content: Text('Please enter a description before submitting.'),
      //       backgroundColor: Colors.redAccent,
      //     ),
      //   );
      //   setState(() => _isLoading = false);
      //   return;
      // }

      final test = widget.allTests[widget.currentIndex];

      Map<String, String> optionResults = {};
      for (int i = 0; i < _selectedOptions.length; i++) {
        optionResults[_selectedOptions[i]] = _optionControllers[i].text.trim();
      }

      await TestingScanningService().updateTesting(test['id'], {
        'queueStatus': 'COMPLETED',
        'result': description,
        'selectedOptionResults': optionResults,
      });

      setState(() {
        _completedList[widget.currentIndex] = true;
      });

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test marked as Completed ✅'),
          backgroundColor: primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSubmit() async {
    // final description = _descriptionController.text.trim();

    // final Map<String, String> optionResults = {};
    // for (var entry in _optionControllers.entries) {
    //   optionResults[entry.key] = entry.value.text.trim();
    // }

    // if (description.isEmpty && optionResults.values.every((v) => v.isEmpty)) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text(
    //         'Please enter a description or option inputs before submitting.',
    //       ),
    //       backgroundColor: Colors.redAccent,
    //     ),
    //   );
    //   return;
    // }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      final Staff_Id = prefs.getString('userId');
      // final patient = widget.allTests[0]['Patient'] ?? {};
      // final consultationList = widget.allTests[0]['ConsultationId'];
      // final int consultationId =
      //     int.tryParse(widget.allTests[0]['consultationId'] ?? '0') ?? 0;
      final consultationId = widget.allTests[0]['consulateId'];
      // final consultationId = consultationList.isNotEmpty
      //     ? consultationList[0]['id']
      //     : null;
      print('widget ${widget.allTests}');
      final List testIds = widget.allTests.map((test) => test['id']).toList();

      for (final id in testIds) {
        await TestingScanningService().updateTesting(id, {
          // 'queueStatus': 'PENDING',
          'status': 'COMPLETED',
          'updatedAt': _dateTime,
          'staff_Id': Staff_Id,
        });
      }
      final bool consultationTest =
          widget.allTests[0]['Patient']['isTestOnly'] ?? false;
      print('consultationTest $consultationTest');
      if (consultationId != null) {
        await ConsultationService().updateConsultation(consultationId, {
          'status': consultationTest == false ? 'ENDPROCESSING' : "COMPLETED",
          'scanningTesting': false,
          'updatedAt': _dateTime,
        });
      }
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All Lab Tests marked as Submitted ✅'),
          backgroundColor: primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool get isCompleted => widget.queueStaus.toUpperCase() == 'COMPLETED';

  // send Selected Options
  Map<String, String> get yourOptionResultsMap {
    final record = widget.allTests[widget.currentIndex];
    final Map<String, dynamic>? savedResults = record['selectedOptionResults'];

    if (savedResults != null) {
      // Map all saved results, assuming they are already filtered
      return savedResults.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    }

    final List<dynamic>? testDetails = record['testDetails'];
    if (testDetails != null && testDetails.isNotEmpty) {
      final options = testDetails[0]['options'] as List<dynamic>? ?? [];
      return {
        for (var option in options)
          if (option['selectedOption'] != null &&
              option['selectedOption'] != 'N/A') // <-- filters N/A
            option['selectedOption'].toString():
                option['result']?.toString() ?? '',
      };
    }

    return {};
  }

  List<Map<String, dynamic>> get yourTestTableList {
    final record = widget.allTests[widget.currentIndex];
    final List<dynamic>? testDetails = record['testDetails'];

    if (testDetails == null || testDetails.isEmpty) return [];

    return testDetails.map((test) {
      final String title =
          (test['title']?.toString().trim().isNotEmpty ?? false)
          ? test['title'].toString()
          : '-';

      final String impression =
          (test['impression']?.toString().trim().isNotEmpty ?? false)
          ? test['impression'].toString()
          : '-';

      final List<dynamic> options = test['options'] as List<dynamic>? ?? [];

      final List<Map<String, String>> results = [];

      for (final opt in options) {
        final selectedOption = opt['selectedOption']?.toString().trim() ?? '';

        // ❌ Stop processing if selected option is "N/A"
        if (selectedOption == 'N/A') break;

        final testName = opt['name']?.toString().trim() ?? '';
        if (testName.isEmpty || testName == 'N/A') continue;

        String clean(String? value) {
          final val = value?.trim() ?? '';
          return (val.isEmpty || val == 'N/A') ? '-' : val;
        }

        results.add({
          'Test': clean(opt['name']),
          'Result': clean(opt['result']),
          'Unit': clean(opt['unit']),
          'Range': clean(opt['reference']),
        });
      }

      return {'title': title, 'impression': impression, 'results': results};
    }).toList();
  }

  Map<String, String> get savedOptionResults {
    final record = widget.allTests[widget.currentIndex];
    final Map<String, dynamic>? resultsMap = record['selectedOptionResults'];
    if (resultsMap != null) {
      return resultsMap.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    }
    return {};
  }

  List<Map<String, dynamic>> get allTestsReportTable {
    List<Map<String, dynamic>> allResults = [];

    for (var test in widget.allTests) {
      final List<dynamic>? testDetails = test['testDetails'];

      if (testDetails != null && testDetails.isNotEmpty) {
        for (var detail in testDetails) {
          final String title = detail['title']?.toString() ?? 'Unknown Test';
          final String impression = detail['results']?.toString() ?? '-';
          final List<dynamic> options =
              detail['options'] as List<dynamic>? ?? [];

          // ✅ Filter valid options (exclude N/A)
          final filteredOptions = options
              .where((opt) => opt['selectedOption'] != 'N/A')
              .map(
                (opt) => {
                  'Test': opt['name']?.toString() ?? '-',
                  'Result': opt['result']?.toString() ?? '-',
                  'Unit': opt['unit']?.toString() ?? '-',
                  'Range': opt['reference']?.toString() ?? '-',
                },
              )
              .toList();

          // ✅ Add grouped test section without summary
          allResults.add({
            'title': title,
            'impression': impression,
            'results': filteredOptions,
          });
        }
      }
    }

    // 🚫 Skip overall summary section
    return allResults;
  }

  Map<String, String> get allTestsOptionResults {
    Map<String, String> results = {};
    for (var test in widget.allTests) {
      final Map<String, dynamic>? savedResults = test['selectedOptionResults'];
      if (savedResults != null) {
        results.addAll(
          savedResults.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          ),
        );
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.allTests[widget.currentIndex];
    final patient = record['Patient'] ?? {};
    final phone = patient['phone']?.toString() ?? 'N/A';

    final patientId = patient['id']?.toString() ?? 'N/A';

    final address = (patient['address'] is Map)
        ? patient['address']['Address'] ?? 'N/A'
        : 'N/A';
    final createdAt = record['createdAt']?.toString() ?? 'N/A';
    final title = record['title']?.toString() ?? 'N/A';
    final dob = _formatDob(patient['dob']?.toString());
    final age = _calculateAge(patient['dob']?.toString());
    final reason = record['reason'] ?? '-';
    final gender = patient['gender']?.toString() ?? 'N/A';
    final bloodGroup = patient['bldGrp']?.toString() ?? 'N/A';
    final doctorName = patient['doctor']?['name'].toString() ?? 'N/A';
    final doctorId = patient['doctor']?['id']?.toString() ?? 'N/A';
    final tokenNo = (patient['tokenNo'] == null || patient['tokenNo'] == 0)
        ? '-'
        : patient['tokenNo'].toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: primaryColor,
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
                  Text(
                    widget.mode == 1 ? "All Lab Reports" : title,
                    style: const TextStyle(
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

      // 🧩 If mode == 1 → show all tests together in one ReportCardWidget
      body: widget.mode == 1
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      // _buildPatientCard(
                      //   name: patient['name']?.toString() ?? 'Unknown',
                      //   id: patientId,
                      //   phone: phone,
                      //   address: address,
                      //   dob: dob,
                      //   age: age,
                      //   gender: gender,
                      //   bloodGroup: bloodGroup,
                      //   createdAt: createdAt,
                      // ),
                      // const SizedBox(height: 20),
                      ReportCardWidget(
                        record: record,
                        doctorName: doctorName,

                        staffName: _labName,

                        hospitalPhotoBase64: logo ?? '',
                        optionResults: allTestsOptionResults,
                        testTable: allTestsReportTable,
                        mode: widget.mode,
                        showButtons: true,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 8,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 14,
                          ),
                        ),
                        onPressed: _isLoading
                            ? null
                            : _handleSubmit, // disable when loading
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Submit',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      if (!isCompleted)
                        _buildPatientCard(
                          name: patient['name']?.toString() ?? 'Unknown',
                          id: patientId,
                          phone: phone,
                          address: address,
                          dob: dob,
                          age: age,

                          tokenNo: tokenNo,
                          // gender: gender,
                          genderColor: _genderColor(gender),
                          genderIcon: _genderIcon(gender),
                          bloodGroup: bloodGroup,
                          createdAt: createdAt,
                        ),
                      const SizedBox(height: 5),

                      // Same logic as before
                      if (isCompleted)
                        ReportCardWidget(
                          record: record,
                          doctorName: doctorName,

                          staffName: _labName,

                          hospitalPhotoBase64: logo ?? '',
                          optionResults: yourOptionResultsMap,
                          testTable: yourTestTableList,
                          mode: widget.mode,
                          showButtons: true,
                        )
                      else ...[
                        if (_selectedOptions.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                "No Options Selected",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          )
                        else
                          _buildMedicalCard(
                            title: title,
                            doctorName: doctorName,
                            reason: reason,
                            doctorId: doctorId,
                            selectedOptions: _selectedOptions,
                            isCompleted: isCompleted,
                          ),
                        if (_selectedOptions.isNotEmpty) ...[
                          const SizedBox(height: 30),
                          _buildInputSection(),
                        ],
                      ],
                      SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildInputSection() {
    bool isCurrentDone = _completedList[widget.currentIndex];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Description",
            style: TextStyle(
              color: primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Enter Lab Test report or notes...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: primaryColor, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading || isCurrentDone ? null : _handleComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              icon: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline, color: Colors.white),
              label: Text(
                isCurrentDone ? "Completed" : "Completed",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard({
    required String name,
    required String id,
    required String phone,
    required String address,
    required String dob,
    required String age,
    required String tokenNo,
    // required String gender,
    required Color genderColor,
    required IconData genderIcon,
    required String bloodGroup,
    required String createdAt,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            // mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(genderIcon, size: 28, color: genderColor),
              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 2),

              GestureDetector(
                onTap: _togglePatientExpand,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Text(
                      //   _isPatientExpanded ? "Hide" : " All",
                      //   style: TextStyle(
                      //     color: primaryColor,
                      //     fontWeight: FontWeight.bold,
                      //   ),
                      // ),
                      Icon(
                        _isPatientExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          Divider(color: Colors.grey.shade300),

          Row(
            //crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Token No: ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                tokenNo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),

          _infoRow("Patient ID", id),
          _infoRow("Cell No", phone),
          _infoRow("Address", address),
          SizeTransition(
            sizeFactor: _patientExpandAnimation,
            axisAlignment: -1.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 30, color: Colors.grey),
                _sectionHeader("Patient Information"),
                const SizedBox(height: 8),
                _infoRow("DOB", dob),
                _infoRow("Age", age),
                // _infoRow("Gender", gender),
                _infoRow("Blood Type", bloodGroup),
                _infoRow("Created At", createdAt),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalCard({
    required String title,
    required String doctorName,
    required String reason,
    required String doctorId,
    required List<String> selectedOptions,
    required bool isCompleted,
  }) {
    final showList = _isXrayExpanded
        ? selectedOptions
        : (selectedOptions.length > 2
              ? selectedOptions.sublist(0, 2)
              : selectedOptions);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Center(
            child: Text(
              title.isEmpty ? "Medical Information" : title,
              style: TextStyle(
                color: primaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const Divider(height: 25, color: Colors.grey),
          _infoRow("Doctor Name", doctorName),
          _infoRow("Doctor ID", doctorId),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Doctor Description ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFBF955E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  reason,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 30, color: Colors.grey),
          _sectionHeader("Selected Options"),
          const SizedBox(height: 10),
          if (selectedOptions.isEmpty)
            const Text(
              "No Options Selected",
              style: TextStyle(color: Colors.grey, fontSize: 15),
            )
          else
            Column(
              children: [
                ...showList.asMap().entries.map((entry) {
                  final int idx = entry.key;
                  final String option = entry.value
                      .trim(); // trim to match keys in map

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 18,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                option,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (!isCompleted)
                          TextField(
                            keyboardType: TextInputType.visiblePassword,

                            controller: _optionControllers[idx],
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText:
                                  'eg Range (${optionReferenceMap[option]})',
                              hintStyle: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[500],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: primaryColor,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          )
                        else
                          Text(
                            _optionControllers[idx].text.trim().isEmpty
                                ? 'N/A'
                                : _optionControllers[idx].text.trim(),
                            style: const TextStyle(fontSize: 15),
                          ),
                      ],
                    ),
                  );
                }).toList(),

                if (selectedOptions.length > 2)
                  TextButton.icon(
                    onPressed: _toggleXrayExpand,
                    icon: Icon(
                      _isXrayExpanded ? Icons.expand_less : Icons.expand_more,
                      color: primaryColor,
                    ),
                    label: Text(
                      _isXrayExpanded ? "Hide" : "View All",
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label + " :",
            style: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? 'N/A' : value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _sectionHeader(String text) => Center(
    child: Text(
      text,
      style: TextStyle(
        color: primaryColor,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    ),
  );
}
