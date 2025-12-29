import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Mediacl_Staff/Pages/OutPatient/Page/InjectionPage.dart';
import '../../../Pages/NotificationsPage.dart';
import '../../../Services/IncomeExpence_Service.dart';

class AccountExpensePage extends StatefulWidget {
  const AccountExpensePage({super.key});

  @override
  State<AccountExpensePage> createState() => _AccountExpensePageState();
}

class _AccountExpensePageState extends State<AccountExpensePage> {
  final IncomeExpenseService _incomeService = IncomeExpenseService();
  bool showForm = false;
  bool _loading = false;
  bool _submitting = false;
  String? _error;

  final TextEditingController reasonController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  String type = 'INCOME';

  List<Map<String, dynamic>> drawers = [];
  double total = 0;

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

  Future<void> fetchDrawers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final fetchedDrawers = await _incomeService.getIncomeExpenseService();
      setState(() {
        drawers = fetchedDrawers
            .map((e) => e as Map<String, dynamic>)
            .where((e) => e['type']?.toString().toUpperCase() == "EXPENSE")
            .toList();

        total = drawers.fold(0, (sum, d) => sum + (d['amount'] as num));
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Error fetching drawers: $e";
        _loading = false;
      });
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
      'type': 'EXPENSE',
      'adminId': adminId,
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
                  " Expense",
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
            isCancel ? 'CANCEL  ' : 'ADD EXPENSE  ',
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
    final bool disabled = _submitting;

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
                    "Expense Details",
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
                enabled: !disabled,
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
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                enabled: !disabled,
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
                onEditingComplete: disabled ? null : createDrawer,
              ),
              const SizedBox(height: 24),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: disabled
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
                  onPressed: disabled ? null : createDrawer,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: disabled
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
                  "Total Expense",
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
                  "₹ ${expense.toStringAsFixed(0)}",
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
