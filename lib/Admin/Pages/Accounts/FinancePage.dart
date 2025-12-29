import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Mediacl_Staff/Pages/OutPatient/Page/InjectionPage.dart';
import '../../../Pages/NotificationsPage.dart';
import '../../../Services/payment_service.dart';

enum FinanceFilter { all, register, medical, test, scan }

enum DateFilter { day, month, year }

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  SharedPreferences? _prefs;
  final PaymentService _api = PaymentService();

  String? hospitalName;
  String? hospitalPlace;
  String? hospitalPhoto;
  FinanceFilter _tempFilter = FinanceFilter.all;
  DateTime _tempDate = DateTime.now(); //DateTime _today = DateTime.now();

  DateTime _selectedDate = DateTime.now();
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;
  DateTime? _rangeStartDate;
  DateTime? _rangeEndDate;

  DateTime? endDate;
  DateTime? startDate;

  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> _allPayments = [];
  List<Map<String, dynamic>> _visiblePayments = [];

  FinanceFilter _selectedFilter = FinanceFilter.all;
  DateFilter _selectedDateFilter = DateFilter.day;

  final DateFormat backendFormat = DateFormat("yyyy-MM-dd hh:mm a");
  // final DateFormat backendFormat = DateFormat("yyyy-MM-dd HH:mm:ss");

  @override
  void initState() {
    super.initState();
    _initPrefs();
    _fetchPaymentsAll();
  }

  // ------------------------------
  // LOAD HOSPITAL FROM STORAGE
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

  Future<void> _fetchPaymentsAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _api.getAllPaidShowAccounts();

      _allPayments = list.map((e) => Map<String, dynamic>.from(e)).toList();

      // Default filter = show today
      final today = DateTime.now();
      _selectedDate = today;
      _rangeStartDate = null;
      _rangeEndDate = null;
      _selectedFilter = FinanceFilter.all;

      _applyFilter();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    // 1) Start from the raw API list
    List<Map<String, dynamic>> base = List.from(_allPayments);

    // 2) Type filter
    switch (_selectedFilter) {
      case FinanceFilter.all:
        break;
      case FinanceFilter.register:
        base = base.where((p) {
          final type = p['type']?.toString().toUpperCase();

          final consultationFee = p['Consultation']?['consultationFee'];

          final hasDoctorFee = consultationFee != null && consultationFee > 0;

          return type == "REGISTRATIONFEE" || hasDoctorFee;
        }).toList();
        break;

      case FinanceFilter.medical:
        base = base
            .where(
              (p) =>
                  p['type']?.toString().toUpperCase() ==
                  "MEDICINETONICINJECTIONFEES",
            )
            .toList();
        break;
      case FinanceFilter.test:
        base = base.where((p) {
          if (p['type']?.toString().toUpperCase() !=
              "TESTINGFEESANDSCANNINGFEE") {
            return false;
          }
          final items = p['TestingAndScanningPatients'] ?? [];
          return items.any((it) {
            final t = (it['type']?.toString() ?? "").toLowerCase();
            return t == "tests" || t == "test";
          });
        }).toList();
        break;
      case FinanceFilter.scan:
        base = base.where((p) {
          if (p['type']?.toString().toUpperCase() !=
              "TESTINGFEESANDSCANNINGFEE") {
            return false;
          }
          final items = p['TestingAndScanningPatients'] ?? [];
          return items.any((it) {
            final t = (it['type']?.toString() ?? "").toLowerCase();
            return t != "tests" && t != "test";
          });
        }).toList();
        break;
    }

    // 3) Parse createdAt to DateTime
    final parsed = base.map((p) {
      final raw = p['createdAt']?.toString() ?? "";
      final dt = _parseDate(raw) ?? DateTime.tryParse(raw);
      return {...p, '_dt': dt ?? DateTime.fromMillisecondsSinceEpoch(0)};
    }).toList();

    // 4) Sort descending by _dt (latest first)
    parsed.sort((a, b) {
      final dta = a['_dt'] as DateTime;
      final dtb = b['_dt'] as DateTime;
      return dtb.compareTo(dta); // latest first
    });

    // 4) Date filtering
    if (_rangeStartDate != null && _rangeEndDate != null) {
      final start = DateTime(
        _rangeStartDate!.year,
        _rangeStartDate!.month,
        _rangeStartDate!.day,
      );
      final end = DateTime(
        _rangeEndDate!.year,
        _rangeEndDate!.month,
        _rangeEndDate!.day,
        23,
        59,
        59,
      );

      parsed.retainWhere((p) {
        final d = p['_dt'] as DateTime;
        return (d.isAtSameMomentAs(start) || d.isAfter(start)) &&
            (d.isAtSameMomentAs(end) || d.isBefore(end));
      });
    } else if (_selectedDateFilter == DateFilter.day) {
      parsed.retainWhere((p) {
        final d = p['_dt'] as DateTime;
        return d.year == _selectedDate.year &&
            d.month == _selectedDate.month &&
            d.day == _selectedDate.day;
      });
    } else if (_selectedDateFilter == DateFilter.month) {
      parsed.retainWhere((p) {
        final d = p['_dt'] as DateTime;
        return d.year == _selectedDate.year && d.month == _selectedDate.month;
      });
    } else if (_selectedDateFilter == DateFilter.year) {
      parsed.retainWhere((p) {
        final d = p['_dt'] as DateTime;
        return d.year == _selectedDate.year;
      });
    }

    // 5) Cleanup _dt key
    final result = parsed.map((p) {
      final copy = Map<String, dynamic>.from(p);
      copy.remove('_dt');
      return copy;
    }).toList();

    setState(() => _visiblePayments = result);
  }

  // ------------------------------
  // DATE PARSER HANDLER
  DateTime? _parseDate(String raw) {
    try {
      return backendFormat.parse(
        raw,
      ); // backendFormat = DateFormat("yyyy-MM-dd hh:mm a")
    } catch (_) {
      try {
        return DateTime.parse(raw);
      } catch (_) {}
    }
    return null;
  }

  //// filter dialog

  void _showFilterDialog() {
    _tempFilter = _selectedFilter;
    _tempDate = _selectedDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),
              child: _buildFilterCard(context, setModalState),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterCard(BuildContext context, Function setModalState) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),

            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row
            Row(
              children: [
                const Spacer(),
                const Text(
                  "Filters",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.brown.shade200,
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            _sectionTitle("Date Range :"),
            buildDateRangeSelector(setModalState),
            const SizedBox(height: 25),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setModalState(() {
                      _tempFilter = FinanceFilter.all;
                      _tempDate = DateTime.now();
                      _rangeStartDate = null;
                      _rangeEndDate = null;
                      startDate = null;
                      endDate = null;
                    });
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    "Reset",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                  ),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: () {
                    setState(() {
                      setState(() {
                        // copy dialog temp values into applied variables
                        _selectedFilter = _tempFilter;
                        _selectedDate = _tempDate;
                        _rangeStartDate = _tempStartDate;
                        _rangeEndDate = _tempEndDate;
                      });
                    });
                    _applyFilter();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Apply",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: Colors.brown.shade700,
        ),
      ),
    );
  }

  Widget buildDateRangeSelector(Function setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _dateBox(
                label: "From",
                date: _rangeStartDate,
                onTap: () async {
                  final pick = await showDatePicker(
                    context: context,
                    initialDate: _rangeStartDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );

                  if (pick != null) {
                    setModalState(() {
                      _rangeStartDate = pick;

                      if (_rangeEndDate != null &&
                          _rangeEndDate!.isBefore(_rangeStartDate!)) {
                        _rangeEndDate = _rangeStartDate;
                      }
                    });
                  }
                },
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _dateBox(
                label: "To",
                date: _rangeEndDate,
                onTap: () async {
                  final pick = await showDatePicker(
                    context: context,
                    initialDate:
                        _rangeEndDate ?? _rangeStartDate ?? DateTime.now(),
                    firstDate: _rangeStartDate ?? DateTime(2020),
                    lastDate: DateTime.now(),
                  );

                  if (pick != null) {
                    setModalState(() {
                      _rangeEndDate = pick;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dateBox({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.brown.shade300),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.brown.withValues(alpha: 0.08),

              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month, size: 18, color: Colors.brown.shade500),
            const SizedBox(width: 8),
            Text(
              date == null ? label : "${date.day}/${date.month}/${date.year}",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.brown.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------
  // UI BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7E6),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _fetchPaymentsAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHospitalCard(),
              const SizedBox(height: 14),
              _buildDateFilterRow(),
              const SizedBox(height: 14),
              _buildFilterRow(),
              const SizedBox(height: 14),
              _buildSummaryCard(),
              const SizedBox(height: 14),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),

              if (_error != null) _buildErrorCard(),

              if (!_loading && _error == null) _buildPaymentsList(),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------
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
                  " Accounts",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.filter_alt, color: Colors.white),
                  onPressed: _showFilterDialog,
                ),
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

  // ------------------------------
  Widget _buildHospitalCard() {
    return Container(
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
                // const SizedBox(height: 4),
                // const Text(
                //   "Showing today's payments",
                //   style: TextStyle(color: Colors.white70, fontSize: 12),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    final filters = {
      FinanceFilter.all: "All",

      FinanceFilter.register: "Reg",
      FinanceFilter.medical: "Med",
      FinanceFilter.test: "Test",
      FinanceFilter.scan: "Scan",
    };

    Widget buildChip(FinanceFilter key, String label) {
      final selected = _selectedFilter == key;

      return AnimatedContainer(
        width: 55,
        height: 45,
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),

        // padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.teal : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.brown.shade300,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.brown.withValues(alpha: 0.2),

                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,

              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.brown,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: filters.entries.map((e) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = e.key;
                  _applyFilter();
                });
              },
              child: buildChip(e.key, e.value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDateFilterRow() {
    // Build chip label dynamically
    String getLabel(DateFilter key) {
      switch (key) {
        case DateFilter.day:
          return _selectedDateFilter == DateFilter.day
              ? DateFormat('dd MMM').format(_selectedDate)
              : "Day";
        case DateFilter.month:
          return _selectedDateFilter == DateFilter.month
              ? DateFormat('MMM').format(_selectedDate)
              : "Month";
        case DateFilter.year:
          return _selectedDateFilter == DateFilter.year
              ? DateFormat('yyyy').format(_selectedDate)
              : "Year";
      }
    }

    Widget buildChip(DateFilter key) {
      final selected = _selectedDateFilter == key;

      return GestureDetector(
        onTap: () async {
          setState(() {
            _selectedDateFilter = key;
          });

          if (key == DateFilter.day) {
            // DAY PICKER
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );

            if (pickedDate != null) {
              setState(() => _selectedDate = pickedDate);
              _applyFilter();
            }
          } else if (key == DateFilter.month) {
            // MONTH PICKER
            final pickedMonth = await showMonthPicker(
              context: context,
              initialDate: _selectedDate,
            );

            if (pickedMonth != null) {
              setState(() {
                _selectedDate = DateTime(
                  pickedMonth.year,
                  pickedMonth.month,
                  1,
                );
              });
              _applyFilter();
            }
          } else if (key == DateFilter.year) {
            // YEAR PICKER
            final pickedYear = await showDialog<int>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("Select Year"),
                content: SizedBox(
                  width: 350,
                  height: 300,
                  child: YearPicker(
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    // initialDate: _selectedDate,
                    selectedDate: _selectedDate,
                    onChanged: (date) {
                      Navigator.pop(ctx, date.year);
                    },
                  ),
                ),
              ),
            );

            if (pickedYear != null) {
              setState(() {
                _selectedDate = DateTime(
                  pickedYear,
                  _selectedDate.month,
                  _selectedDate.day,
                );
              });
              _applyFilter();
            }
          }
        },

        child: AnimatedContainer(
          width: 80,
          height: 55,
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 12),
          // padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.redAccent : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: selected ? Colors.transparent : Colors.brown.shade300,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.brown.withValues(alpha: 0.2),

                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              getLabel(key),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.brown,
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: DateFilter.values.map((key) => buildChip(key)).toList(),
      ),
    );
  }

  Widget _buildSummaryCard() {
    double sum(value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // TOTALS
    double totalAll = 0;
    double totalRegister = 0;

    double totalRegisterCash = 0;
    double totalRegisterOnline = 0;
    double totalMedical = 0;
    double totalMedicalCash = 0;
    double totalMedicalOnline = 0;
    double totalTest = 0;
    double totalTestCash = 0;
    double totalTestOnline = 0;
    double totalScan = 0;
    double totalScanCash = 0;
    double totalScanOnline = 0;
    //
    // double totalCash =
    //     totalRegisterCash + totalMedicalCash + totalTestCash + totalScanCash;
    // double totalOnline =
    //     totalRegisterOnline +
    //     totalMedicalOnline +
    //     totalTestOnline +
    //     totalScanOnline;

    double medMedicine = 0;
    double medTonic = 0;
    double medInjection = 0;

    double totalDoctorFee = 0;

    Map<String, Map<String, dynamic>> doctorFeeTotals = {};

    Map<String, double> scanTypeTotals = {};

    String shortName(String name, {int max = 10}) {
      if (name.length <= max) return name;
      return "${name.substring(0, max)}...";
    }

    String? getDoctorName(Map<String, dynamic> p) {
      final staffId = p['Consultation']['doctor_Id'];
      final hospital = p['Hospital'];
      if (staffId == null || hospital == null) return null;

      final admins = hospital['Admins'];
      if (admins is! List) return null;

      for (final admin in admins) {
        if (admin['user_Id'] == staffId && admin['status'] == 'ACTIVE') {
          return admin['name'];
        }
      }
      return null;
    }

    for (var p in _visiblePayments) {
      final type = (p["type"] ?? "").toString().toUpperCase();
      final paymentType = (p["paymentType"] ?? "").toString().toUpperCase();

      final amount = sum(p["amount"]);

      totalAll += amount;

      // // DOCTOR FEE
      // final consultation = p['Consultation'];
      // if (consultation != null) {
      //   final fee = sum(consultation['consultationFee']);
      //   final doctorName = consultation['doctorName'] ?? "Doctor";
      //
      //   if (fee >= 0) {
      //     totalDoctorFee += fee;
      //     doctorFeeTotals[doctorName] =
      //         (doctorFeeTotals[doctorName] ?? 0) + fee;
      //   }
      // }
      // DOCTOR FEE (CONSULTATION)

      // final consultation = p['Consultation'];
      //
      // if (consultation != null && consultation['consultationFee'] != null) {
      //   final double fee = sum(consultation['consultationFee']);
      //
      //   if (fee > 0) {
      //     final doctorId = p['staff_Id']?.toString();
      //     final doctorName = getDoctorName(p);
      //
      //     // ❌ Skip empty doctor
      //     if (doctorId == null || doctorName == null || doctorName.isEmpty) {
      //       continue; // skip this iteration only
      //     }
      //
      //     totalDoctorFee += fee;
      //
      //     doctorFeeTotals[doctorName] =
      //         (doctorFeeTotals[doctorName] ?? 0) + fee;
      //   }
      // }

      final consultation = p['Consultation'];

      if (consultation != null && consultation['consultationFee'] != null) {
        final double fee = sum(consultation['consultationFee']);

        if (fee <= 0) continue;

        final String? doctorId = consultation['doctor_Id']?.toString();
        final String? doctorName = getDoctorName(p);

        // Skip empty doctor
        if (doctorId == null || doctorName == null || doctorName.isEmpty) {
          continue;
        }

        totalDoctorFee += fee;

        if (!doctorFeeTotals.containsKey(doctorId)) {
          doctorFeeTotals[doctorId] = {'name': doctorName, 'total': fee};
        } else {
          doctorFeeTotals[doctorId]!['total'] =
              (doctorFeeTotals[doctorId]!['total'] as double) + fee;
        }
      }

      // REGISTRATION
      if (type == "REGISTRATIONFEE") {
        totalRegister += amount;
        if (paymentType == "MANUALPAY") totalRegisterCash += amount;
        if (paymentType == "ONLINEPAY") totalRegisterOnline += amount;
      }

      // MEDICAL
      if (type == "MEDICINETONICINJECTIONFEES") {
        totalMedical += amount;

        if (paymentType == "MANUALPAY") totalMedicalCash += amount;
        if (paymentType == "ONLINEPAY") totalMedicalOnline += amount;

        for (var m in p["MedicinePatient"] ?? []) {
          medMedicine += (m['total'] ?? 0);
        }
        for (var t in p["TonicPatient"] ?? []) {
          medTonic += (t['total'] ?? 0);
        }

        for (var i in p["InjectionPatient"] ?? []) {
          medInjection += (i['total'] ?? 0);
        }
      }

      // TESTING AND SCANNING
      if (type == "TESTINGFEESANDSCANNINGFEE") {
        for (var entry in p["TestingAndScanningPatients"] ?? []) {
          final subType = (entry["type"] ?? "").toString().toLowerCase();
          final subAmt = entry["amount"] ?? p["amount"] ?? 0;

          // Split by cash/online
          if (subType == "tests" || subType == "test") {
            totalTest += subAmt;
            if (paymentType == "MANUALPAY") totalTestCash += subAmt;
            if (paymentType == "ONLINEPAY") totalTestOnline += subAmt;
          } else {
            totalScan += subAmt;
            scanTypeTotals[subType] = (scanTypeTotals[subType] ?? 0) + subAmt;
            if (paymentType == "MANUALPAY") totalScanCash += subAmt;
            if (paymentType == "ONLINEPAY") totalScanOnline += subAmt;
          }
        }
      }
    }

    // Totals
    double totalCash =
        totalRegisterCash + totalMedicalCash + totalTestCash + totalScanCash;
    double totalOnline =
        totalRegisterOnline +
        totalMedicalOnline +
        totalTestOnline +
        totalScanOnline;

    // ----------- UI COMPONENT REUSABLE ----------
    Widget statCard(String title, double value, {Color color = Colors.blue}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),

              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(
                  "₹ ${value.toStringAsFixed(1)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    Widget cashStatCard(
      String title,
      double value, {
      Color color = Colors.blue,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: title == 'Cash'
                ? Colors.green.withValues(alpha: 0.6)
                : Colors.blueAccent.withValues(alpha: 0.6),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: title == 'Cash'
                    ? Colors.green.shade700
                    : Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "₹ ${value.toStringAsFixed(1)}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      );
    }

    Widget statCardCustom({
      required String doctorId,
      required String doctorName,
      required double amount,
      required Color color,
    }) {
      return Card(
        color: color,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.grey.shade400, // 👈 border color
            width: 1, // 👈 border thickness
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "ID: $doctorId",
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                shortName(doctorName),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "₹${amount.toStringAsFixed(1)}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget statCardTitleCustom({
      required String title,
      required double amount,
      required Color color,
    }) {
      return SizedBox(
        width: double.infinity,
        child: Card(
          color: color,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade400, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),

                // 💰 AMOUNT (TOP)
                Text(
                  "₹${amount.toStringAsFixed(1)}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                // 🏷 TITLE (UNDER VALUE)
              ],
            ),
          ),
        ),
      );
    }

    List<Widget> rows = [];

    // -----------------------------------------------------------
    // ***************   FILTER-WISE UI BUILDER   ****************
    // -----------------------------------------------------------

    if (_selectedFilter == FinanceFilter.all) {
      rows.add(statCard("Total Collection", totalAll, color: Colors.green));
      rows.add(const SizedBox(height: 12));

      rows.add(
        Row(
          children: [
            Expanded(
              child: cashStatCard("Cash", totalCash, color: Colors.purple),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: cashStatCard("Online", totalOnline, color: Colors.red),
            ),
          ],
        ),
      );
      rows.add(const SizedBox(height: 12));

      rows.add(
        Row(
          children: [
            Expanded(
              child: statCard(
                "Registration",
                totalRegister,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: statCard("Medical", totalMedical, color: Colors.blue),
            ),
          ],
        ),
      );

      rows.add(const SizedBox(height: 12));

      rows.add(
        Row(
          children: [
            Expanded(child: statCard("Test", totalTest, color: Colors.purple)),
            const SizedBox(width: 12),
            Expanded(child: statCard("Scan", totalScan, color: Colors.red)),
          ],
        ),
      );

      rows.add(const SizedBox(height: 12));
    }

    // REGISTER
    if (_selectedFilter == FinanceFilter.register) {
      rows.add(
        statCard(
          "Registration Collection",
          totalRegister,
          color: Colors.orange,
        ),
      );

      rows.add(const SizedBox(height: 12));

      rows.add(
        Row(
          children: [
            Expanded(
              child: cashStatCard(
                "Cash",
                totalRegisterCash,
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: cashStatCard(
                "Online",
                totalRegisterOnline,
                color: Colors.red,
              ),
            ),
          ],
        ),
      );
      rows.add(const SizedBox(height: 12));
      // TOTAL DOCTOR FEE
      rows.add(
        statCardTitleCustom(
          title: "Doctor Fee Collection",
          amount: totalDoctorFee,
          color: Colors.grey.shade200,
        ),
      );

      rows.add(const SizedBox(height: 10));

      // DOCTOR-WISE BREAKDOWN (2 per row)
      final doctorList = doctorFeeTotals.entries.toList();

      for (var i = 0; i < doctorList.length; i += 2) {
        final chunk = doctorList.skip(i).take(2).toList();

        rows.add(
          Row(
            children: chunk.map((e) {
              final String doctorId = e.key;
              final String doctorName = e.value['name'] as String;
              final double total = e.value['total'] as double;

              return Expanded(
                child: statCardCustom(
                  doctorId: doctorId,
                  doctorName: doctorName,
                  amount: total,
                  color: Colors.grey.shade200,
                ),
              );
            }).toList(),
          ),
        );


        rows.add(const SizedBox(height: 12));
      }
    }

    // MEDICAL
    if (_selectedFilter == FinanceFilter.medical) {
      rows.add(statCard("Medical Total", totalMedical, color: Colors.blue));
      rows.add(const SizedBox(height: 12));

      rows.add(
        Row(
          children: [
            Expanded(
              child: cashStatCard(
                "Cash",
                totalMedicalCash,
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: cashStatCard(
                "Online",
                totalMedicalOnline,
                color: Colors.red,
              ),
            ),
          ],
        ),
      );
      rows.add(const SizedBox(height: 12));

      rows.add(
        Row(
          children: [
            Expanded(
              child: statCard("Medicine", medMedicine, color: Colors.green),
            ),
            const SizedBox(width: 12),
            Expanded(child: statCard("Tonic", medTonic, color: Colors.teal)),
          ],
        ),
      );

      rows.add(const SizedBox(height: 12));
      rows.add(statCard("Injection", medInjection, color: Colors.red));

      rows.add(const SizedBox(height: 12));
    }

    // // TEST
    // if (_selectedFilter == FinanceFilter.test) {
    //   rows.add(statCard("Test Collection", totalTest, color: Colors.purple));
    // }
    if (_selectedFilter == FinanceFilter.test && totalTest > 0) {
      rows.add(statCard("Test Collection", totalTest, color: Colors.purple));

      rows.add(const SizedBox(height: 12));

      rows.add(
        Row(
          children: [
            Expanded(
              child: cashStatCard("Cash", totalTestCash, color: Colors.purple),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: cashStatCard(
                "Online",
                totalRegisterOnline,
                color: Colors.red,
              ),
            ),
          ],
        ),
      );

      // 1. Get all test entries
      final testEntries = _visiblePayments
          .expand((p) => p["TestingAndScanningPatients"] ?? [])
          .where((e) {
            final type = (e["type"] ?? "").toString().toLowerCase();
            return type == "test" || type == "tests";
          });

      // 1. Combine totals and count duplicates by title
      final Map<String, double> combinedTests = {};
      final Map<String, int> testCounts = {}; // count of each title

      for (var e in testEntries) {
        final title = e["title"] ?? "Unknown Test";
        final amount = sum(e["amount"]);

        combinedTests[title] = (combinedTests[title] ?? 0) + amount;
        testCounts[title] = (testCounts[title] ?? 0) + 1;
      }

      // 2. Display cards 2 per row with count
      final titlesList = combinedTests.entries.toList();
      for (var i = 0; i < titlesList.length; i += 2) {
        final chunk = titlesList.skip(i).take(2).toList();

        rows.add(
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: chunk.map((e) {
                final count = testCounts[e.key] ?? 1;
                return Expanded(
                  child: statCard(
                    "${e.key} ( $count )", // show title + length
                    e.value,
                    color: Colors.purple.shade200,
                  ),
                );
              }).toList(),
            ),
          ),
        );

        rows.add(const SizedBox(height: 12));
      }
    }

    // SCAN
    if (_selectedFilter == FinanceFilter.scan && totalScan > 0) {
      // Main total card
      rows.add(statCard("Scan Collection", totalScan, color: Colors.red));
      rows.add(const SizedBox(height: 12));

      rows.add(
        Row(
          children: [
            Expanded(
              child: cashStatCard("Cash", totalScanCash, color: Colors.purple),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: cashStatCard("Online", totalScanOnline, color: Colors.red),
            ),
          ],
        ),
      );
      rows.add(const SizedBox(height: 12));

      // Step 1: Combine totals and count per scan type
      final Map<String, double> combinedScans = {};
      final Map<String, int> scanCounts = {};

      for (var p in _visiblePayments) {
        final type = (p["type"] ?? "").toString().toUpperCase();
        if (type != "TESTINGFEESANDSCANNINGFEE") continue;

        for (var entry in p["TestingAndScanningPatients"] ?? []) {
          final subType = (entry["type"] ?? "").toString().toLowerCase();

          // Skip test entries
          if (subType == "test" || subType == "tests") continue;

          // Amount: use entry amount if exists, else parent amount
          final amount = sum(entry["amount"]) > 0
              ? sum(entry["amount"])
              : sum(p["amount"]);

          combinedScans[subType] = (combinedScans[subType] ?? 0) + amount;
          scanCounts[subType] =
              (scanCounts[subType] ?? 0) + 1; // count occurrences
        }
      }

      // Step 2: Display scan type cards 2 per row
      final scanList = combinedScans.entries.toList();
      for (var i = 0; i < scanList.length; i += 2) {
        final chunk = scanList.skip(i).take(2).toList();

        rows.add(
          Padding(
            padding: const EdgeInsets.only(top: 2), // spacing between rows
            child: Row(
              children: chunk.map((e) {
                final count = scanCounts[e.key] ?? 1;
                return Expanded(
                  child: statCard(
                    "${e.key.toUpperCase()} ( $count )", // show type + count
                    e.value,
                    color: Colors.red.shade200,
                  ),
                );
              }).toList(),
            ),
          ),
        );

        rows.add(const SizedBox(height: 12));
      }
    }

    //
    //   // GRID view for scan types
    //   rows.add(
    //     GridView.count(
    //       crossAxisCount: 2,
    //       shrinkWrap: true,
    //       physics: const NeverScrollableScrollPhysics(),
    //       childAspectRatio: 2.3,
    //       children: scanTypeTotals.entries.map((e) {
    //         return statCard(e.key.toUpperCase(), e.value, color: Colors.brown);
    //       }).toList(),
    //     ),
    //   );
    // }

    // -----------------------------------------------------------

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),

            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEDBA77), Color(0xFFC59A62)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.assessment, color: Colors.white, size: 26),
                const SizedBox(width: 10),
                const Text(
                  "Today's Summary",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white30,
                  child: Text(
                    "${_visiblePayments.length}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          ...rows,
        ],
      ),
    );
  }

  // ------------------------------
  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
          TextButton(onPressed: _fetchPaymentsAll, child: const Text("Retry")),
        ],
      ),
    );
  }

  Color darken(Color color, [double amount = .25]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  Widget _buildPaymentsList() {
    if (_visiblePayments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          "No Payments Found Today",
          style: TextStyle(color: Colors.black45, fontSize: 16),
        ),
      );
    }

    // Assign subtle card color by payment type
    Color getCardColor(Map<String, dynamic> payment) {
      final type = (payment["type"] ?? "").toString().toUpperCase();

      switch (type) {
        case "REGISTRATIONFEE":
          return const Color(0xFFE8FBE8); // light green

        case "MEDICINETONICINJECTIONFEES":
          return const Color(0xFFF8F6D9); // soft pink

        case "TESTINGFEESANDSCANNINGFEE":
          final items = payment["TestingAndScanningPatients"] ?? [];

          final hasTest = items.any((e) {
            final t = (e["type"] ?? "").toString().toLowerCase();
            return t == "test" || t == "tests";
          });

          final hasScan = items.any((e) {
            final t = (e["type"] ?? "").toString().toLowerCase();
            return t != "test" && t != "tests";
          });

          if (hasTest) return const Color(0xFFF4E1CD); // test
          if (hasScan) return const Color(0xFFC8EFEF); // scan
          return Colors.grey.shade100;

        default:
          return Colors.grey.shade100;
      }
    }

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _visiblePayments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final p = _visiblePayments[i];

            // DATE
            final dt = _parseDate(p['createdAt'] ?? "");
            final time = dt != null
                ? DateFormat("hh:mm a").format(dt)
                : (p['createdAt'] ?? "-");

            // PATIENT

            final patient = p['Patient']?['name'] ?? '-';
            final patientId = p['Patient']?['id'] ?? '-';

            // CARD COLOR
            final bgColor = getCardColor(p);
            final borderColor = darken(bgColor, 0.06);

            // AMOUNT
            final double amount = (p['amount'] is num)
                ? (p['amount'] as num).toDouble()
                : double.tryParse("${p['amount']}") ?? 0.0;

            return Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: borderColor, // Perfect dark border
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),

                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    // Row 1: Name + Amount
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            patient,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          "₹ ${amount.toStringAsFixed(1)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // Row 2: ID + Time
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "ID: $patientId",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
