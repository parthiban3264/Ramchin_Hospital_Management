import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../Services/patient_service.dart';

class BloodGrpPage extends StatefulWidget {
  const BloodGrpPage({super.key});

  @override
  State<BloodGrpPage> createState() => _BloodGrpPageState();
}

class _BloodGrpPageState extends State<BloodGrpPage> {
  final PatientService _service = PatientService();

  Map<String, dynamic>? bloodData;
  List patients = [];
  List filteredPatients = [];

  bool isLoading = true;
  String searchText = "";
  bool showOnlyAvailable = false;

  @override
  void initState() {
    super.initState();
    fetchBloodData();
  }

  /// 📡 FETCH DATA
  Future<void> fetchBloodData() async {
    try {
      final data = await _service.getBloodGroupData();

      setState(() {
        bloodData = data;
        patients = data["patients"] ?? [];
        filteredPatients = patients;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => isLoading = false);
    }
  }

  final formatter = DateFormat('yyyy-MM-dd hh:mm a');

  /// 🧠 CHECK AVAILABLE (3 MONTH RULE)
  bool isAvailable(String? donateDate) {
    if (donateDate == null) return true;

    final lastDate = formatter.parse(donateDate);

    final nextEligible = DateTime(
      lastDate.year,
      lastDate.month + 3,
      lastDate.day,
    );

    return DateTime.now().isAfter(nextEligible);
  }

  /// 📅 DAYS REMAINING
  int daysRemaining(String? donateDate) {
    if (donateDate == null) return 0;

    final lastDate = formatter.parse(donateDate);

    final nextEligible = DateTime(
      lastDate.year,
      lastDate.month + 3,
      lastDate.day,
    );

    final diff = nextEligible.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  /// 🔍 FILTER
  void filterPatients(String value) {
    setState(() {
      searchText = value.toLowerCase();

      filteredPatients = patients.where((p) {
        final id = p["id"].toString();
        final phone = p["phone"]?.toString() ?? "";
        final group = p["bldGrp"]?.toString().toLowerCase() ?? "";

        final matchesSearch =
            id.contains(value) ||
            phone.contains(value) ||
            group.contains(searchText);

        final available = isAvailable(p["bld_donate_date"]);

        return matchesSearch && (!showOnlyAvailable || available);
      }).toList();
    });
  }

  /// 📞 CALL
  Future<void> callPatient(String phone) async {
    final Uri url = Uri.parse("tel:$phone");

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloodGroups = bloodData?["bloodGroupCount"] ?? {};

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          height: 100,
          decoration: const BoxDecoration(
            color: Color(0xFFBF955E),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  "Blood Donor Dash",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // IconButton(
                //   icon: const Icon(Icons.notifications, color: Colors.white),
                //   onPressed: () {},
                // ),
                IconButton(
                  icon: const Icon(Icons.home, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                /// 🔴 TOTAL CARD
                // Padding(
                //   padding: const EdgeInsets.all(12),
                //   child: _buildTotalCard(),
                // ),

                /// 🩸 BLOOD GROUP CHIPS
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: bloodGroups.entries.map<Widget>((entry) {
                      return _buildBloodGroupChip(entry.key, entry.value);
                    }).toList(),
                  ),
                ),

                /// 🔍 SEARCH
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: TextField(
                    onChanged: filterPatients,
                    decoration: InputDecoration(
                      hintText: "Search by ID / Phone / Blood Group",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                /// 🔘 TOGGLE
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.favorite, color: Colors.red),
                          SizedBox(width: 10),
                          Text(
                            "Show Available Donors",
                            style: TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                      Transform.scale(
                        scale: 0.9,
                        child: Switch.adaptive(
                          value: showOnlyAvailable,
                          activeColor: Colors.red,
                          onChanged: (val) {
                            setState(() {
                              showOnlyAvailable = val;
                              filterPatients(searchText);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                /// 📋 LIST
                Expanded(
                  child: filteredPatients.isEmpty
                      ? const Center(child: Text("No Patients Found"))
                      : ListView.builder(
                          itemCount: filteredPatients.length,
                          itemBuilder: (context, index) {
                            final p = filteredPatients[index];
                            return _buildPatientCard(p);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  /// 🔴 TOTAL CARD
  // Widget _buildTotalCard() {
  //   return Card(
  //     elevation: 5,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  //     child: ListTile(
  //       leading: const Icon(Icons.people, color: Colors.red),
  //       title: const Text("Total Donors"),
  //       trailing: Text(
  //         bloodData?["totalPatient"].toString() ?? "0",
  //         style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //       ),
  //     ),
  //   );
  // }

  /// 🩸 BLOOD CHIP
  Widget _buildBloodGroupChip(String group, int count) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            group,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getGenderIcon(String? gender) {
    if (gender == null) return Icons.person;

    switch (gender.toLowerCase()) {
      case "male":
        return Icons.male;
      case "female":
        return Icons.female;
      default:
        return Icons.transgender;
    }
  }

  Color _getGenderColor(String? gender) {
    if (gender == null) return Colors.grey;

    switch (gender.toLowerCase()) {
      case "male":
        return Colors.blue;
      case "female":
        return Colors.pink;
      default:
        return Colors.purple;
    }
  }

  /// 👤 PATIENT CARD
  Widget _buildPatientCard(Map<String, dynamic> p) {
    final available = isAvailable(p["bld_donate_date"]);
    final remainingDays = daysRemaining(p["bld_donate_date"]);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        // leading: CircleAvatar(
        //   backgroundColor: available
        //       ? Colors.green.shade100
        //       : Colors.grey.shade300,
        //   child: Text(
        //     p["bldGrp"] ?? "?",
        //     style: TextStyle(
        //       color: available ? Colors.green : Colors.grey,
        //       fontWeight: FontWeight.bold,
        //     ),
        //   ),
        // ),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: available
                  ? Colors.green.shade100
                  : Colors.grey.shade300,
              child: Text(
                p["bldGrp"] ?? "?",
                style: TextStyle(
                  color: available ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),

            /// 🔹 Gender Icon (top-right)
            Positioned(
              right: 0,
              bottom: 0,
              child: CircleAvatar(
                radius: 10,
                backgroundColor: Colors.white,
                child: Icon(
                  _getGenderIcon(p["gender"]),
                  size: 15,
                  color: _getGenderColor(p["gender"]),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          p["name"] ?? "Unknown",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ID: ${p["id"]}"),
            Text("Phone: ${p["phone"]['mobile'] ?? '-'}"),
            Text("Address: ${p["address"]['Address'] ?? '-'}"),
            const SizedBox(height: 4),
            Text(
              available
                  ? "🟢 Available"
                  : "🔴 Available in $remainingDays days",
              style: TextStyle(
                color: available ? Colors.green : Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.call, color: Colors.green),
          onPressed: available
              ? () => callPatient(p["phone"]['mobile'] ?? "")
              : null,
        ),
      ),
    );
  }
}
