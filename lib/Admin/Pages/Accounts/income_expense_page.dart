import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Mediacl_Staff/Pages/OutPatient/Page/injection_page.dart';
import '../../../Pages/NotificationsPage.dart';
import '../../../Services/IncomeExpence_Service.dart';

class AccountIncomePage extends StatefulWidget {
  const AccountIncomePage({super.key});

  @override
  State<AccountIncomePage> createState() => _AccountIncomePageState();
}

class _AccountIncomePageState extends State<AccountIncomePage> {
  final IncomeExpenseService _incomeService = IncomeExpenseService();
  bool showForm = false;
  bool _loading = false;
  bool _submitting = false;
  String? _error;

  final TextEditingController reasonController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  String type = 'INCOME';

  List<Map<String, dynamic>> _allDrawers = [];
  List<Map<String, dynamic>> drawers = [];
  double total = 0;
  DateTime _selectedDate = DateTime.now();

  // Hospital info
  String? hospitalName;
  String? hospitalPlace;
  String? hospitalPhoto;
  String? _dateTime;
  SharedPreferences? _prefs;
  @override
  void initState() {
    super.initState();
    _initPrefs();
    fetchDrawers();
    _updateTime();
  }

  void _updateTime() {
    _dateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _loadHospitalInfo();
  }

  void _loadHospitalInfo() {
    hospitalName = _prefs?.getString('hospitalName') ?? "Unknown";
    hospitalPlace = _prefs?.getString('hospitalPlace') ?? "Unknown";
    hospitalPhoto =
        _prefs?.getString('hospitalPhoto') ??
        "https://as1.ftcdn.net/v2/jpg/02/50/38/52/1000_F_250385294_tdzxdr2Yzm5Z3J41fBYbgz4PaVc2kQmT.jpg";
    setState(() {});
  }

  void _filterDrawers() {
    String selectedDateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
    setState(() {
      drawers = _allDrawers.where((d) {
        String? createdAt = d['createdAt'] as String?;
        if (createdAt != null && createdAt.length >= 10) {
          return createdAt.substring(0, 10) == selectedDateString;
        }
        return false;
      }).toList();
      total = drawers.fold(0, (sum, d) => sum + (d['amount'] as num));
    });
  }

  Future<void> fetchDrawers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final fetchedDrawers = await _incomeService.getIncomeExpenseService();
      _allDrawers = fetchedDrawers
          .map((e) => e as Map<String, dynamic>)
          .where((e) => e['type']?.toString().toUpperCase() == "INCOME")
          .toList();

      _filterDrawers();

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Error fetching drawers: $e";
        _loading = false;
      });
    }
  }

  Future<void> deleteDrawer(int id) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Income', style: TextStyle(color: Colors.red)),
        content: const Text('Are you sure you want to delete this Income?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      await _incomeService.deleteIncomeExpense(id);
      await fetchDrawers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Income deleted successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = "Error deleting: $e";
      });
    }
  }

  Future<void> updateDrawer(Map<String, dynamic> drawer) async {
    final TextEditingController editReason = TextEditingController(
      text: drawer['reason'],
    );
    final TextEditingController editAmount = TextEditingController(
      text: drawer['amount'].toString(),
    );

    bool? update = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Income'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editReason,
              decoration: InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: editAmount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (update != true) return;

    if (editReason.text.trim().isEmpty || editAmount.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reason and Amount cannot be empty')),
        );
      }
      return;
    }

    setState(() => _loading = true);
    try {
      final updatedData = {
        'reason': editReason.text.trim(),
        'amount': double.tryParse(editAmount.text.trim()) ?? 0,
      };
      await _incomeService.updateIncomeExpense(
        int.parse(drawer['id'].toString()),
        updatedData,
      );
      await fetchDrawers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Income updated successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = "Error updating: $e";
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              onSurface: Colors.teal.shade900,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.teal),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _filterDrawers();
    }
  }

  Future<void> createDrawer() async {
    if (reasonController.text.isEmpty || amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter reason and amount.')),
      );
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });

    final adminId = _prefs?.getString('userId');
    final hospitalId = _prefs?.getString('hospitalId');
    final data = {
      'hospital_Id': int.parse(hospitalId!),
      'reason': reasonController.text.trim(),
      'amount': double.tryParse(amountController.text.trim()) ?? 0,
      'type': 'INCOME',
      'admin_Id': adminId,
      'createdAt': _dateTime,
    };
    try {
      await _incomeService.createIncomeExpenseService(data);
      reasonController.clear();
      amountController.clear();
      setState(() {
        showForm = false;
        _submitting = false;
      });
      await fetchDrawers();
    } catch (e) {
      setState(() {
        _error = "Error creating drawer: $e";
        _submitting = false;
      });
    }
  }
  // Future<List<dynamic>> getIncomeExpenseService() async {
  //   final hospitalId = await getHospitalId();
  //   final url = Uri.parse('$baseUrl/income_and_expense/getAll/$hospitalId');
  //
  //   final response = await http.get(url);
  //
  //   if (response.statusCode == 200) {
  //     return jsonDecode(response.body);
  //   } else {
  //     throw Exception('Failed to fetch drawers: ${response.body}');
  //   }
  // }
  //
  // Future<bool> updateIncomeExpense(int id, Map<String, dynamic> data) async {
  //   final response = await http.patch(
  //     Uri.parse("$baseUrl/income_and_expense/$id"),
  //     headers: {"Content-Type": "application/json"},
  //     body: jsonEncode(data),
  //   );
  //
  //   if (response.statusCode == 200 || response.statusCode == 201) {
  //     return true;
  //   } else {
  //     print(response.body);
  //     return false;
  //   }
  // }
  //edit updateIncomeExpense()
  //remove updateIncomeExpense()

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              _buildHospitalCard(),
              const SizedBox(height: 10),
              _buildDatePicker(),
              const SizedBox(height: 2),
              _buildTotalCard(),
              _buildAddDrawerButton(),
              if (showForm) _buildFormCard(),
              if (_error != null) _buildErrorCard(_error!),
              const SizedBox(height: 8),
              Container(
                height: 400,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: _loading
                    ? _buildLoadingIndicator()
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: drawers.length,
                        itemBuilder: (context, index) {
                          final drawer = drawers[index];
                          final drawerType =
                              (drawer['type'] as String?)?.toUpperCase() ??
                              'INCOME';
                          final isIncome = drawerType == 'INCOME';
                          final String typeLetter = isIncome ? "INC" : "EXP";

                          final Color cardColor = isIncome
                              ? Colors.lightBlue.shade100
                              : Colors.red.shade100;

                          final Color textColor = isIncome
                              ? Colors.blue.shade900
                              : Colors.red.shade900;

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.only(
                              top: 10,
                              bottom: 10,
                              left: 8,
                              right: 18,
                            ),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                  child: Text(
                                    typeLetter,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        drawer['reason'] ?? '',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        drawer['admin_Id'] ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: textColor.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                      ),
                                      if (drawer['id'] != null) ...[
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            InkWell(
                                              onTap: () => updateDrawer(drawer),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.withValues(
                                                    alpha: 0.15,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.edit,
                                                      size: 14,
                                                      color:
                                                          Colors.blue.shade700,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Edit',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors
                                                            .blue
                                                            .shade700,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            InkWell(
                                              onTap: () => deleteDrawer(
                                                int.parse(
                                                  drawer['id'].toString(),
                                                ),
                                              ),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withValues(
                                                    alpha: 0.15,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.delete,
                                                      size: 14,
                                                      color:
                                                          Colors.red.shade700,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Delete',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Colors.red.shade700,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Text(
                                  '₹ ${(drawer['amount'] ?? 0).toString()}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
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
                const Text(
                  " Income",
                  style: TextStyle(
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalCard() {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEDBA77), Color(0xFFC59A62)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Image.network(
              hospitalPhoto ?? "",
              height: 60,
              width: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.local_hospital,
                color: Colors.white,
                size: 55,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hospitalName ?? "",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hospitalPlace ?? "",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddDrawerButton() {
    final bool isCancel = showForm;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          icon: Icon(
            isCancel ? Icons.close_rounded : Icons.add_rounded,
            size: 26,
            color: Colors.white,
          ),
          label: Text(
            isCancel ? 'CANCEL  ' : 'ADD Income  ',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isCancel
                ? const Color(0xFFE57373)
                : const Color(0xFF26A69A),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          onPressed: _submitting
              ? null
              : () {
                  setState(() => showForm = !showForm);
                },
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    bool isSubmitting = _submitting;
    bool isButtonDisabled =
        isSubmitting ||
        reasonController.text.trim().isEmpty ||
        amountController.text.trim().isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.teal.shade50.withValues(alpha: 0.4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.shade200.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.medical_services_rounded,
                      color: Colors.teal,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Income Details",
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: Colors.teal.shade700,
                    ),
                  ),
                ],
              ),
              // const SizedBox(height: 18),
              // DropdownButtonFormField<String>(
              //   value: type,
              //   decoration: InputDecoration(
              //     labelText: "Type",
              //     prefixIcon: Icon(
              //       Icons.swap_vert_rounded,
              //       color: Colors.teal.shade700,
              //     ),
              //     filled: true,
              //     fillColor: Colors.white,
              //     border: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(16),
              //     ),
              //     enabledBorder: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(16),
              //       borderSide: BorderSide(
              //         color: Colors.teal.shade200,
              //         width: 1.4,
              //       ),
              //     ),
              //   ),
              //   items: ['INCOME', 'EXPENSE']
              //       .map(
              //         (e) => DropdownMenuItem(
              //           value: e,
              //           child: Text(e.toUpperCase()),
              //         ),
              //       )
              //       .toList(),
              //   onChanged: disabled
              //       ? null
              //       : (val) => setState(() => type = val!),
              // ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                enabled: !isSubmitting,
                decoration: InputDecoration(
                  labelText: "Reason",
                  prefixIcon: Icon(
                    Icons.description_rounded,
                    color: Colors.teal.shade700,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.teal.shade200,
                      width: 1.4,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onChanged: (e) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                enabled: !isSubmitting,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: "Amount",
                  prefixIcon: Icon(
                    Icons.currency_rupee,
                    color: Colors.teal.shade700,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.teal.shade200,
                      width: 1.4,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onChanged: (e) => setState(() {}),
                onEditingComplete: isButtonDisabled ? null : createDrawer,
              ),
              const SizedBox(height: 24),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: isButtonDisabled
                        ? [Colors.grey.shade400, Colors.grey.shade500]
                        : [Colors.teal.shade600, Colors.teal.shade400],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.shade300.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: isButtonDisabled ? null : createDrawer,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Submit",
                          style: TextStyle(
                            fontSize: 17,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCard() {
    double income = 0;
    double expense = 0;

    for (var d in drawers) {
      if (d['type'] == 'INCOME') {
        income += (d['amount'] as num).toDouble();
      } else {
        expense += (d['amount'] as num).toDouble();
      }
    }

    double net = income - expense;
    bool isPositive = net >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isPositive ? Colors.green.shade300 : Colors.red.shade300,
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_rounded,
                  color: isPositive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 10),
                Text(
                  "Total Summary",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isPositive
                        ? Colors.green.shade900
                        : Colors.red.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Income Row
            // Row(
            //   children: [
            //     const Text(
            //       "Income:",
            //       style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            //     ),
            //     const Spacer(),
            //     Text(
            //       "₹ ${income.toStringAsFixed(0)}",
            //       style: TextStyle(
            //         fontSize: 16,
            //         fontWeight: FontWeight.bold,
            //         color: Colors.green.shade700,
            //       ),
            //     ),
            //   ],
            // ),
            //
            // const SizedBox(height: 6),

            // Expense Row
            // Row(
            //   children: [
            //     const Text(
            //       "Expense:",
            //       style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            //     ),
            //     const Spacer(),
            //     Text(
            //       "₹ ${expense.toStringAsFixed(0)}",
            //       style: TextStyle(
            //         fontSize: 16,
            //         fontWeight: FontWeight.bold,
            //         color: Colors.red.shade700,
            //       ),
            //     ),
            //   ],
            // ),
            //
            // const SizedBox(height: 12),

            // Divider
            Divider(
              color: isPositive ? Colors.green.shade200 : Colors.red.shade200,
              thickness: 1.2,
            ),

            const SizedBox(height: 10),

            // NET BALANCE
            Row(
              children: [
                Text(
                  // isPositive ? "Net Balance:" : "Excess Expense:",
                  "Total Income",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isPositive
                        ? Colors.green.shade900
                        : Colors.red.shade900,
                  ),
                ),
                const Spacer(),
                Text(
                  "₹ ${income.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isPositive
                        ? Colors.green.shade900
                        : Colors.red.shade900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: Colors.teal.shade700,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Selected Date",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd MMM yyyy').format(_selectedDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () => _selectDate(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade50,
                foregroundColor: Colors.teal.shade700,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              child: const Text(
                'Change',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorCard(String error) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        color: Colors.red.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: const Icon(Icons.error, color: Colors.red),
          title: Text(error, style: const TextStyle(color: Colors.red)),
          trailing: TextButton(
            onPressed: fetchDrawers,
            child: const Text('Retry'),
          ),
        ),
      ),
    );
  }
}
