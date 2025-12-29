import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Services/admin_service.dart';

class ActiveStaffPage extends StatefulWidget {
  const ActiveStaffPage({super.key});

  @override
  State<ActiveStaffPage> createState() => _ActiveStaffPageState();
}

class _ActiveStaffPageState extends State<ActiveStaffPage> {
  final AdminService service = AdminService();

  List<dynamic> staffList = [];
  List<dynamic> filteredList = [];

  String searchText = "";
  bool isLoadingPage = true;

  // Track toggle loading for each staff ID
  Map<int, bool> toggleLoading = {};

  @override
  void initState() {
    super.initState();
    loadStaff();
  }

  // ------------------------- LOAD STAFF ONLY ONCE ------------------------- //
  void loadStaff() async {
    setState(() => isLoadingPage = true);

    final data = await service.getMedicalStaff();

    final nonAdmins = data
        .where((s) => s["role"].toString().toLowerCase() != "admin")
        .toList();

    setState(() {
      staffList = nonAdmins;
      filteredList = nonAdmins;
      isLoadingPage = false;
    });
  }

  // ---------------------- SEARCH FILTER ------------------------- //
  void filterSearch(String text) {
    setState(() {
      searchText = text.toLowerCase();
      filteredList = staffList.where((s) {
        final name = s["name"].toString().toLowerCase();
        final id = s["user_Id"].toString().toLowerCase();

        final des = s["role"].toString().toLowerCase();

        return name.contains(searchText) ||
            id.contains(searchText) ||
            des.contains(searchText);
      }).toList();
    });
  }

  // ------------- UPDATE STATUS WITHOUT RELOADING THE WHOLE PAGE ---------- //
  void changeStatus(int id, bool newStatus) async {
    setState(() {
      toggleLoading[id] = true; // enable loader only for selected toggle
    });

    await service.updateStatus(id, newStatus);

    final prefs = await SharedPreferences.getInstance();
    final String statusText = newStatus ? "ACTIVE" : "INACTIVE";

    await prefs.setString("staffStatus", statusText);

    setState(() {
      for (var s in staffList) {
        if (s["id"] == id) {
          s["status"] = statusText;
        }
      }

      for (var s in filteredList) {
        if (s["id"] == id) {
          s["status"] = statusText;
        }
      }

      toggleLoading[id] = false; // stop loader
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),

      // ------------------------- APP BAR ------------------------- //
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFFBF955E),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "Active & InActive",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  // IconButton(
                  //   icon: const Icon(
                  //     Icons.notifications,
                  //     color: Colors.white,
                  //     size: 26,
                  //   ),
                  //   onPressed: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (_) => const NotificationPage(),
                  //       ),
                  //     );
                  //   },
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
      // ------------------------- BODY ------------------------- //
      body: Column(
        children: [
          const SizedBox(height: 20),

          // ------------------------- SEARCH BAR ------------------------- //
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                onChanged: filterSearch,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Colors.grey),

                  hintText: "Search by Name, ID, or Role...",
                ),
              ),
            ),
          ),

          const SizedBox(height: 2),

          // ------------------------- MAIN CONTENT ------------------------- //
          Expanded(
            child: isLoadingPage
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFBF955E)),
                  )
                : filteredList.isEmpty
                ? const Center(
                    child: Text(
                      "No Staff Found",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final staff = filteredList[index];

                      final bool isActive =
                          staff["status"].toString().toUpperCase() == "ACTIVE";

                      final bool isSwitchLoading =
                          toggleLoading[staff["id"]] == true;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 7),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.07),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: const Color(0xFFEEE0C9),
                              child: Text(
                                staff["name"][0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 22,
                                  color: Color(0xFF8A6D3B),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            const SizedBox(width: 16),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    staff["name"],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    "ID: ${staff['user_Id']}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    "Role: ${staff['role']}",

                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            // ---------------- ACTIVE / INACTIVE + SWITCH ---------------- //
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.green.withValues(alpha: 0.15)
                                        : Colors.red.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isActive ? "ACTIVE" : "INACTIVE",
                                    style: TextStyle(
                                      color: isActive
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                // ----------- LOADING SWITCH ----------- //
                                isSwitchLoading
                                    ? const Padding(
                                        padding: EdgeInsets.only(top: 6),
                                        child: SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      )
                                    : Switch(
                                        value: isActive,
                                        activeColor: Colors.green,
                                        inactiveThumbColor: Colors.red,
                                        onChanged: (value) {
                                          changeStatus(staff["id"], value);
                                        },
                                      ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
