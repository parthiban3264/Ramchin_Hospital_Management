import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hospitrax/Mediacl_Staff/Pages/billing/create_billing_page.dart';
import 'package:hospitrax/utils/utils.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Admin/Pages/admin_edit_profile_page.dart';
import '../../../Pages/NotificationsPage.dart';
import 'bill_pdf_generator.dart';

enum FoodTiming { beforeFood, afterFood, notApplicable }

/// A medicine the user has confirmed and added to the current bill.
class SelectedMedicine {
  final Map<String, dynamic> medicine;
  int quantity;
  final Set<String> sessions; // Morning / Afternoon / Night
  FoodTiming foodTiming;

  SelectedMedicine({
    required this.medicine,
    required this.quantity,
    required this.sessions,
    required this.foodTiming,
  });

  double get total => _priceOf(medicine) * quantity;
}

/// -----------------------------------------------------------------------
/// Small helpers to safely pull fields out of the raw API map.
/// Your backend shape (from getAllMedicineData) looks like:
/// { "_id": ..., "name": ..., "category": ..., "stock": ...,
///   "batches": [ { "batch_no": ..., "selling_price_unit": ..., "rack_no": ... } ] }
/// -----------------------------------------------------------------------

String _idOf(Map<String, dynamic> medicine) {
  final id = medicine['_id'] ?? medicine['id'];
  return id?.toString() ??
      medicine['name']?.toString() ??
      medicine.hashCode.toString();
}

String _nameOf(Map<String, dynamic> medicine) =>
    medicine['name']?.toString() ?? 'Unknown';

String _categoryOf(Map<String, dynamic> medicine) =>
    medicine['category']?.toString() ?? '-';

int _stockOf(Map<String, dynamic> medicine) {
  final stock = medicine['stock'];
  if (stock is int) return stock;
  if (stock is num) return stock.toInt();
  return int.tryParse(stock?.toString() ?? '') ?? 0;
}

List<dynamic> _batchesOf(Map<String, dynamic> medicine) {
  final batches = medicine['batches'];
  return batches is List ? batches : const [];
}

double _priceOf(Map<String, dynamic> medicine) {
  final batches = _batchesOf(medicine);
  if (batches.isEmpty) return 0;
  final price = batches.first['selling_price_unit'];
  if (price is num) return price.toDouble();
  return double.tryParse(price?.toString() ?? '') ?? 0;
}

String _batchNoOf(Map<String, dynamic> medicine) {
  final batches = _batchesOf(medicine);
  if (batches.isEmpty) return '-';
  return batches.first['batch_no']?.toString() ?? '-';
}

/// -----------------------------------------------------------------------
/// PAGE
/// -----------------------------------------------------------------------

class ListMedicinePage extends StatefulWidget {
  const ListMedicinePage({super.key});

  @override
  State<ListMedicinePage> createState() => _ListMedicinePageState();
}

class _ListMedicinePageState extends State<ListMedicinePage> {
  List<Map<String, dynamic>> _allMedicines = [];

  Future<void> getAllMedicineData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hospitalId = prefs.getString('hospitalId');
      final res = await http.get(
        Uri.parse('$baseUrl/medicine/getAll/$hospitalId'),
      );
      final jsonData = jsonDecode(res.body);
      final medicines = List<Map<String, dynamic>>.from(jsonData['data']);

      setState(() {
        _allMedicines = medicines;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load medicines: ${e.toString()}')),
      );
    }
  }

  Future<void> _createBill() async {
    if (_selectedMedicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one medicine first')),
      );
      return;
    }

    final medicinesForBill = _selectedMedicines.map((item) {
      final m = item.medicine;
      return {
        'name': _nameOf(m),
        'quantityNeeded': item.quantity,
        'batchNo': _batchNoOf(m),
        'itemLength': m.length,
        'after_food':
            item.foodTiming == FoodTiming.beforeFood, // true = before (B)
        'morning': item.sessions.contains('Morning'),
        'afternoon': item.sessions.contains('Afternoon'),
        'night': item.sessions.contains('Night'),
        'days':
            1, // you don't currently track "days"; default to 1 or add a field
        'category': _categoryOf(m).toLowerCase(),
        'medicine': m, // includes batches + category for expiry/initial lookup
        'total': item.total,
      };
    }).toList();

    await BillPdfGenerator.generateAndPrintBill(
      medicines: medicinesForBill,
      totalAmount: _totalAmount,
      hospitalData: hospitalData,
    );

    // Optional: still go to CreateBillingPage after printing
    if (!mounted) return;
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (_) => const ()),
    // );
  }

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Map<String, dynamic>> _filteredMedicines = [];
  String? _expandedMedicineId;

  // Draft state for the currently expanded card, keyed by medicine id.
  final Map<String, int> _draftQuantity = {};
  Map<String, dynamic> hospitalData = {};
  final Map<String, Set<String>> _draftSessions = {};
  final Map<String, FoodTiming> _draftFoodTiming = {};

  final List<SelectedMedicine> _selectedMedicines = [];

  @override
  void initState() {
    super.initState();
    getAllMedicineData();
    _searchController.addListener(_onSearchChanged);
    loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final hospitalName = prefs.getString('hospitalName');
    final hospitalId = prefs.getString('hospitalId');
    final hospitalPhoto = prefs.getString('hospitalPhoto');
    final hospitalAddress = prefs.getString('hospitalPlace');

    setState(() {
      hospitalData = {
        "id": hospitalId,
        "hospitalName": hospitalName,
        "hospitalPhoto": hospitalPhoto,
        "hospitalAddress": hospitalAddress,
      };
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMedicines = [];
        _expandedMedicineId = null;
      } else {
        _filteredMedicines = _allMedicines
            .where((m) => _nameOf(m).toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _toggleExpand(Map<String, dynamic> medicine) {
    final id = _idOf(medicine);
    setState(() {
      if (_expandedMedicineId == id) {
        _expandedMedicineId = null;
      } else {
        _expandedMedicineId = id;
        _draftQuantity.putIfAbsent(id, () => 1);
        _draftSessions.putIfAbsent(id, () => <String>{});
        _draftFoodTiming.putIfAbsent(id, () => FoodTiming.afterFood);
      }
    });
  }

  void _changeQuantity(Map<String, dynamic> medicine, int delta) {
    final id = _idOf(medicine);
    setState(() {
      final current = _draftQuantity[id] ?? 1;
      final next = (current + delta).clamp(1, 999);
      _draftQuantity[id] = next;
    });
  }

  void _toggleSession(Map<String, dynamic> medicine, String session) {
    final id = _idOf(medicine);
    setState(() {
      final set = _draftSessions[id] ?? <String>{};
      if (set.contains(session)) {
        set.remove(session);
      } else {
        set.add(session);
      }
      _draftSessions[id] = set;
    });
  }

  void _setFoodTiming(Map<String, dynamic> medicine, FoodTiming timing) {
    final id = _idOf(medicine);
    setState(() {
      _draftFoodTiming[id] = timing;
    });
  }

  void _addMedicineToBill(Map<String, dynamic> medicine) {
    final id = _idOf(medicine);
    final sessions = _draftSessions[id] ?? <String>{};
    if (sessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one session')),
      );
      return;
    }

    final selected = SelectedMedicine(
      medicine: medicine,
      quantity: _draftQuantity[id] ?? 1,
      sessions: Set.from(sessions),
      foodTiming: _draftFoodTiming[id] ?? FoodTiming.afterFood,
    );

    setState(() {
      _selectedMedicines.add(selected);
      _expandedMedicineId = null;
      _searchController.clear();
      _filteredMedicines = [];
      _draftQuantity.remove(id);
      _draftSessions.remove(id);
      _draftFoodTiming.remove(id);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).requestFocus(_searchFocusNode);
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${_nameOf(medicine)} added'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _removeSelected(int index) {
    setState(() => _selectedMedicines.removeAt(index));
  }

  int get _totalItems =>
      _selectedMedicines.fold(0, (sum, item) => sum + item.quantity);

  double get _totalAmount =>
      _selectedMedicines.fold(0.0, (sum, item) => sum + item.total);

  // void _createBill() {
  //   if (_selectedMedicines.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Add at least one medicine first')),
  //     );
  //     return;
  //   }
  //
  //   // Hand off to your existing billing flow. Adjust the constructor args
  //   // to match whatever CreateBillingPage actually expects.
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (_) => const CreateBillingPage()),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: primaryColor,
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "Medicine Billing",
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
                  IconButton(
                    icon: const Icon(Icons.home, color: Colors.white),
                    onPressed: () {
                      int count = 0;
                      Navigator.popUntil(context, (route) => count++ >= 1);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 90),
              child: ListView(
                children: [
                  _buildSearchBar(),
                  if (_filteredMedicines.isNotEmpty) _buildSearchResults(),
                  _buildSelectedList(),
                ],
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBillingSummary(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: SearchBar(
        controller: _searchController,
        focusNode: _searchFocusNode,
        hintText: 'Search medicine...',
        hintStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontSize: 15,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
        leading: const Icon(Icons.search, color: Colors.grey),
        trailing: _searchController.text.isNotEmpty
            ? [
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _expandedMedicineId = null);
                  },
                ),
              ]
            : null,
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        elevation: const WidgetStatePropertyAll(1),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16),
        ),
        side: WidgetStatePropertyAll(
          BorderSide(width: 1, color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 420),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 8),
        itemCount: _filteredMedicines.length,
        itemBuilder: (context, index) {
          final medicine = _filteredMedicines[index];
          final id = _idOf(medicine);
          final isExpanded = _expandedMedicineId == id;
          final inStock = _stockOf(medicine) > 0;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            elevation: isExpanded ? 4 : 1,
            shadowColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            color: Colors.white,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: inStock ? () => _toggleExpand(medicine) : null,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Icon(
                          //   inStock ? Icons.inventory_2 : Icons.cancel,
                          //   color: inStock ? Colors.green : Colors.red,
                          //   size: 26,
                          // ),
                          // const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nameOf(medicine),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '${_categoryOf(medicine)} • ₹${_priceOf(medicine).toStringAsFixed(2)} • Batch ${_batchNoOf(medicine)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: Colors.grey.shade500,
                          ),
                        ],
                      ),
                      if (isExpanded) ...[
                        const Divider(height: 20),
                        _buildExpandedContent(medicine),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpandedContent(Map<String, dynamic> medicine) {
    final id = _idOf(medicine);
    final qty = _draftQuantity[id] ?? 1;
    final sessions = _draftSessions[id] ?? <String>{};
    final foodTiming = _draftFoodTiming[id] ?? FoodTiming.afterFood;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quantity selector
        Row(
          children: [
            const Text(
              'Quantity :',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            SizedBox(width: 12),
            _quantityButton(Icons.remove, () => _changeQuantity(medicine, -1)),
            Container(
              width: 36,
              alignment: Alignment.center,
              child: Text(
                '$qty',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _quantityButton(Icons.add, () => _changeQuantity(medicine, 1)),
            const Spacer(),
            // Food timing
            const Text(
              'Food :',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(width: 12),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                setState(() {
                  switch (foodTiming) {
                    case FoodTiming.afterFood:
                      _setFoodTiming(medicine, FoodTiming.beforeFood);
                      break;
                    case FoodTiming.beforeFood:
                      _setFoodTiming(medicine, FoodTiming.notApplicable);
                      break;
                    case FoodTiming.notApplicable:
                      _setFoodTiming(medicine, FoodTiming.afterFood);
                      break;
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: switch (foodTiming) {
                    FoodTiming.afterFood => Colors.green.shade50,
                    FoodTiming.beforeFood => Colors.orange.shade50,
                    FoodTiming.notApplicable => Colors.grey.shade200,
                  },
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: switch (foodTiming) {
                      FoodTiming.afterFood => Colors.green,
                      FoodTiming.beforeFood => Colors.orange,
                      FoodTiming.notApplicable => Colors.grey,
                    },
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      switch (foodTiming) {
                        FoodTiming.afterFood => Icons.restaurant,
                        FoodTiming.beforeFood => Icons.schedule,
                        FoodTiming.notApplicable => Icons.remove_circle_outline,
                      },
                      size: 14,
                      color: switch (foodTiming) {
                        FoodTiming.afterFood => Colors.green,
                        FoodTiming.beforeFood => Colors.orange,
                        FoodTiming.notApplicable => Colors.grey,
                      },
                    ),
                    const SizedBox(width: 6),
                    Text(
                      switch (foodTiming) {
                        FoodTiming.afterFood => "AC",
                        FoodTiming.beforeFood => "BC",
                        FoodTiming.notApplicable => "N/A",
                      },
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: switch (foodTiming) {
                          FoodTiming.afterFood => Colors.green,
                          FoodTiming.beforeFood => Colors.orange,
                          FoodTiming.notApplicable => Colors.grey,
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Session selection
        const Text(
          'Session :',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Wrap(
              spacing: 12,
              children:
                  [
                    {'label': 'MN', 'value': 'Morning'},
                    {'label': 'AN', 'value': 'Afternoon'},
                    {'label': 'NT', 'value': 'Night'},
                  ].map((item) {
                    final selected = sessions.contains(item['value']);

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(
                          scale: 0.9, // Try 0.7 or 0.75 for even smaller
                          child: Checkbox(
                            value: selected,
                            activeColor: primaryColor,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            onChanged: (_) =>
                                _toggleSession(medicine, item['value']!),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          item['label']!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
            ),
            Spacer(),
            // Add button
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => _addMedicineToBill(medicine),
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  "ADD ",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  //minimumSize: const Size(90, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quantityButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: primaryColor),
      ),
    );
  }

  Widget _buildSelectedList() {
    if (_selectedMedicines.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.blue.shade50,
              child: Icon(
                Icons.medication_outlined,
                size: 38,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "No Medicines Added",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              "Search and add medicines to create the bill.",
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    String _sessionShort(Set<String> sessions) {
      const map = {
        'Morning': 'MN',
        'Afternoon': 'AN',
        'Night': 'NT',
        'MN': 'MN',
        'AN': 'AN',
        'NT': 'NT',
      };

      return sessions.map((e) => map[e] ?? e).join(" -  ");
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      itemCount: _selectedMedicines.length,
      separatorBuilder: (_, __) => const SizedBox(height: 2),
      itemBuilder: (context, index) {
        final item = _selectedMedicines[index];

        final foodLabel = item.foodTiming == FoodTiming.beforeFood
            ? "Before Food"
            : "After Food";

        return Card(
          elevation: 1,
          color: Colors.white,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.medication_rounded,
                    color: primaryColor,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _nameOf(item.medicine),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),

                          Text(
                            "₹${item.total.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 7),

                      Row(
                        children: [
                          _badge("Qty ${item.quantity}"),

                          const SizedBox(width: 6),

                          _badge(_sessionShort(item.sessions)),

                          const SizedBox(width: 6),

                          _badge(
                            item.foodTiming == FoodTiming.beforeFood
                                ? "PC"
                                : "AC",
                            bg: item.foodTiming == FoodTiming.beforeFood
                                ? Colors.orange.shade50
                                : Colors.green.shade50,
                            fg: item.foodTiming == FoodTiming.beforeFood
                                ? Colors.orange.shade700
                                : Colors.green.shade700,
                          ),

                          const Spacer(),

                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _removeSelected(index),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _badge(
    String text, {
    Color bg = const Color(0xFFF5F5F5),
    Color fg = Colors.black87,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  Widget _buildBillingSummary() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Items: $_totalItems',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${_totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _createBill,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Create Bill',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
