import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import '../../../../Pages/NotificationsPage.dart';
import '../../../../Services/payment_service.dart';
import '../Page/SymptomsPage.dart';

class SymptomsQueuePage extends StatefulWidget {
  const SymptomsQueuePage({Key? key}) : super(key: key);

  @override
  State<SymptomsQueuePage> createState() => _SymptomsQueuePageState();
}

class _SymptomsQueuePageState extends State<SymptomsQueuePage>
    with TickerProviderStateMixin {
  late Future<List<dynamic>> futurePatients;

  final Color primaryColor = const Color(0xFFBF955E);

  late TabController topTabController; // Today / Previous
  late TabController bottomTabController; // Queue / History

  String searchText = '';

  @override
  void initState() {
    super.initState();
    futurePatients = PaymentService().getAllPaid();
    topTabController = TabController(length: 2, vsync: this);
    bottomTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    topTabController.dispose();
    bottomTabController.dispose();
    super.dispose();
  }

  /// ---------------- DATE HELPERS ----------------
  DateTime? parseApiDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateFormat('yyyy-MM-dd hh:mm a').parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  bool isToday(String? dateStr) {
    final date = parseApiDate(dateStr);
    if (date == null) return false;

    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _formatDate(String? dateStr) {
    final date = parseApiDate(dateStr);
    if (date == null) return "N/A";
    return DateFormat('dd MMM yyyy').format(date);
  }

  String formatDob(String? dob) {
    if (dob == null || dob.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dob);
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (_) {
      return dob;
    }
  }

  String calculateAge(String? dob) {
    if (dob == null || dob.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dob);
      final now = DateTime.now();
      int age = now.year - date.year;
      if (now.month < date.month ||
          (now.month == date.month && now.day < date.day)) {
        age--;
      }
      return "$age";
    } catch (_) {
      return 'N/A';
    }
  }

  /// ---------------- BUILD ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      /// ---------------- APP BAR (UNCHANGED) ----------------
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
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
                    "Vitals Queue",
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

      /// ---------------- BODY ----------------
      body: FutureBuilder<List<dynamic>>(
        future: futurePatients,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Lottie.asset('assets/Lottie/NoData.json', width: 250),
            );
          }

          final data = snapshot.data!;

          /// 🔹 FILTER DATA (DATE + QUEUE/HISTORY + SEARCH)
          final filtered = data.where((item) {
            final consultation = item['Consultation'] ?? {};
            final patient = item['Patient'] ?? {};
            final createdAt = item['createdAt'];

            final isHistoryTab = bottomTabController.index == 1;
            final symptoms = consultation['symptoms'] ?? false;

            final statusMatch = isHistoryTab
                ? symptoms == true
                : symptoms == false;

            final dateMatch = topTabController.index == 0
                ? isToday(createdAt)
                : !isToday(createdAt);

            final searchMatch =
                searchText.isEmpty ||
                patient['name'].toString().toLowerCase().contains(searchText) ||
                patient['id'].toString().contains(searchText);

            return statusMatch && dateMatch && searchMatch;
          }).toList();

          return Column(
            children: [
              TabBar(
                controller: topTabController,
                indicatorColor: primaryColor,
                labelColor: primaryColor,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: "Today"),
                  Tab(text: "Previous"),
                ],
                onTap: (_) => setState(() {}),
              ),

              /// 🔹 SEARCH BOX
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search by ID or Name",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => searchText = val.toLowerCase());
                  },
                ),
              ),

              /// 🔹 LIST (UI SAME)
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Lottie.asset(
                          'assets/Lottie/NoData.json',
                          width: 220,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final consultation = item['Consultation'];
                          final patient = item['Patient'] ?? {};
                          final createdAt = item['createdAt'];

                          final tokenNo =
                              consultation['tokenNo'] == null ||
                                  consultation['tokenNo'] == 0
                              ? '-'
                              : consultation['tokenNo'].toString();

                          return GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SymptomsPage(
                                    patient: patient,
                                    consultationId: item['consultation_Id'],
                                    sugarData:
                                        consultation['sugerTest'] ?? false,
                                    sugar: consultation['sugar'].toString(),
                                    consultationData: consultation,
                                    mode: 1,
                                    history: true,
                                    index: bottomTabController.index,
                                  ),
                                ),
                              );

                              if (result == true) {
                                setState(() {
                                  futurePatients = PaymentService()
                                      .getAllPaid();
                                });
                              }
                            },

                            /// 🔹 ORIGINAL CARD UI (UNCHANGED)
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.07),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: primaryColor.withValues(alpha: 0.15),
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Text(
                                      (patient['name'] ?? 'Unknown').toString(),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),

                                  Divider(
                                    color: primaryColor,
                                    thickness: 1.4,
                                    height: 4,
                                    indent: 50,
                                    endIndent: 50,
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
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
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _infoRow(
                                    Icons.badge_outlined,
                                    "ID",
                                    patient['id'].toString(),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.cake_outlined,
                                        size: 20,
                                        color: primaryColor,
                                      ),
                                      const SizedBox(width: 10),
                                      Text('DOB: ${formatDob(patient['dob'])}'),
                                      const SizedBox(width: 20),
                                      Text(
                                        'AGE: ${calculateAge(patient['dob'])}',
                                      ),
                                    ],
                                  ),
                                  _infoRow(
                                    Icons.wc_outlined,
                                    "Gender",
                                    patient['gender'].toString(),
                                  ),
                                  _infoRow(
                                    Icons.access_time_outlined,
                                    "Created",
                                    _formatDate(createdAt),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),

      /// ---------------- BOTTOM TABS ----------------
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: TabBar(
          controller: bottomTabController,

          /// 🔹 TOP INDICATOR
          indicator: BoxDecoration(
            border: Border(top: BorderSide(color: primaryColor, width: 3)),
          ),

          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,

          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),

          tabs: const [
            Tab(text: "Queue"),
            Tab(text: "History"),
          ],

          onTap: (_) => setState(() {}),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: primaryColor.withValues(alpha: 0.8), size: 18),
          const SizedBox(width: 10),
          Text(
            "$label:",
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54, fontSize: 14.5),
            ),
          ),
        ],
      ),
    );
  }
}
