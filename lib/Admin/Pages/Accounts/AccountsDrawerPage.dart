import 'package:flutter/material.dart';
import 'package:hospitrax/Services/payment_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Mediacl_Staff/Pages/OutPatient/Page/InjectionPage.dart';
import '../../../Pages/NotificationsPage.dart';
import '../../../Services/drawer_Service.dart';

enum DateFilter { day, month, year }

class AccountDrawerPage extends StatefulWidget {
  const AccountDrawerPage({super.key});

  @override
  State<AccountDrawerPage> createState() => _AccountDrawerPageState();
}

class _AccountDrawerPageState extends State<AccountDrawerPage> {
  final DrawerService _drawerService = DrawerService();
  final PaymentService _paymentService = PaymentService();

  SharedPreferences? _prefs;

  bool showForm = false;
  bool _loading = false;

  final TextEditingController reasonController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  String type = 'OUT';

  List<Map<String, dynamic>> drawers = [];
  List<Map<String, dynamic>> payments = [];
  List<Map<String, dynamic>> visibleDrawers = [];
  List<Map<String, dynamic>> visiblePayments = [];

  double totalIN = 0;
  double totalOUT = 0;
  double totalPayment = 0;
  double balance = 0;

  String? hospitalName;
  String? hospitalPlace;
  String? hospitalPhoto;
  String? _dateTime;

  DateFilter _selectedDateFilter = DateFilter.month;
  final DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  @override
  void initState() {
    super.initState();
    _initPrefs();
    _updateTime();

    fetchPayments().then((_) {
      fetchDrawers();
    });
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
    });

    try {
      final fetchedDrawers = await _drawerService.getDrawers();
      drawers = fetchedDrawers
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _applyDrawerFilter();
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> fetchPayments() async {
    setState(() {
      _loading = true;
    });

    try {
      final fetchedPayments = await _paymentService.getAllPaidShowAccounts();
      payments = fetchedPayments
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _applyPaymentFilter();
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  void _applyDrawerFilter() {
    List<Map<String, dynamic>> filtered = [];
    totalIN = 0;
    totalOUT = 0;

    for (var d in drawers) {
      DateTime? dt;
      try {
        dt = DateFormat("yyyy-MM-dd hh:mm a").parse(d['createdAt']);
      } catch (_) {
        continue;
      }

      if ((_selectedDateFilter == DateFilter.day &&
              dt.year == _selectedDate.year &&
              dt.month == _selectedDate.month &&
              dt.day == _selectedDate.day) ||
          (_selectedDateFilter == DateFilter.month &&
              dt.year == _selectedDate.year &&
              dt.month == _selectedDate.month) ||
          (_selectedDateFilter == DateFilter.year &&
              dt.year == _selectedDate.year)) {
        filtered.add(d);

        final amt = (d['amount'] as num).toDouble();
        d['type'] == 'IN' ? totalIN += amt : totalOUT += amt;
      }
    }

    visibleDrawers = filtered;
    balance = totalPayment + totalIN - totalOUT;
    setState(() {});
  }

  void _applyPaymentFilter() {
    List<Map<String, dynamic>> filtered = [];
    totalPayment = 0;

    for (var p in payments) {
      DateTime? dt;
      try {
        dt = DateFormat("yyyy-MM-dd hh:mm a").parse(p['createdAt']);
      } catch (_) {
        continue;
      }

      if ((_selectedDateFilter == DateFilter.day &&
              dt.year == _selectedDate.year &&
              dt.month == _selectedDate.month &&
              dt.day == _selectedDate.day) ||
          (_selectedDateFilter == DateFilter.month &&
              dt.year == _selectedDate.year &&
              dt.month == _selectedDate.month) ||
          (_selectedDateFilter == DateFilter.year &&
              dt.year == _selectedDate.year)) {
        filtered.add(p);
        totalPayment += (p['amount'] as num).toDouble();
      }
    }

    visiblePayments = filtered;
    balance = totalPayment + totalIN - totalOUT;
    setState(() {});
  }

  void _applyFilter() {
    _applyDrawerFilter();
    _applyPaymentFilter();
  }

  Future<void> createDrawer() async {
    if (reasonController.text.isEmpty || amountController.text.isEmpty) return;

    final enteredAmount = double.tryParse(amountController.text) ?? 0;
    if (enteredAmount <= 0) return;

    if (type == 'OUT' && enteredAmount > balance) return;

    final adminId = _prefs?.getString('userId');
    final hospitalId = _prefs?.getString('hospitalId');

    if (adminId == null || hospitalId == null) return;

    final data = {
      'hospital_Id': int.parse(hospitalId),
      'reason': reasonController.text.trim(),
      'amount': enteredAmount,
      'type': type,
      'admin_Id': adminId,
      'createdAt': _dateTime,
    };

    try {
      await _drawerService.createDrawer(data);
      reasonController.clear();
      amountController.clear();
      showForm = false;
      await fetchDrawers();
    } catch (e) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHospitalCard(),
                  _buildDateFilterRow(),
                  _buildTotalCard(),
                  _buildAddDrawerButton(),
                  if (showForm) _buildFormCard(),
                  _buildDrawerList(),
                ],
              ),
            ),
    );
  }

  // ---------------- UI METHODS (UNCHANGED DESIGN) ----------------

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text("Drawing"),
      backgroundColor: primaryColor,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHospitalCard() {
    return ListTile(
      leading: CircleAvatar(backgroundImage: NetworkImage(hospitalPhoto!)),
      title: Text(hospitalName ?? ''),
      subtitle: Text(hospitalPlace ?? ''),
    );
  }

  Widget _buildDateFilterRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: DateFilter.values.map((e) {
        return Padding(
          padding: const EdgeInsets.all(6),
          child: ChoiceChip(
            label: Text(e.name.toUpperCase()),
            selected: _selectedDateFilter == e,
            onSelected: (_) {
              setState(() => _selectedDateFilter = e);
              _applyFilter();
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTotalCard() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Column(
        children: [
          ListTile(title: Text("IN : ₹$totalIN")),
          ListTile(title: Text("OUT : ₹$totalOUT")),
          ListTile(title: Text("Cash : ₹$balance")),
        ],
      ),
    );
  }

  Widget _buildAddDrawerButton() {
    return ElevatedButton(
      onPressed: () => setState(() => showForm = !showForm),
      child: Text(showForm ? "Cancel" : "Add Drawing"),
    );
  }

  Widget _buildFormCard() {
    return Column(
      children: [
        TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: "Reason"),
        ),
        TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Amount"),
        ),
        ElevatedButton(onPressed: createDrawer, child: const Text("Submit")),
      ],
    );
  }

  Widget _buildDrawerList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visibleDrawers.length,
      itemBuilder: (_, i) {
        final d = visibleDrawers[i];
        return ListTile(
          title: Text(d['reason']),
          trailing: Text("₹${d['amount']}"),
        );
      },
    );
  }
}
