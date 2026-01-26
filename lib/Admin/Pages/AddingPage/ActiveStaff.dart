import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Services/admin_service.dart';
import '../../../utils/utils.dart';

class ActiveStaffPage extends StatefulWidget {
  const ActiveStaffPage({super.key});

  @override
  State<ActiveStaffPage> createState() => _ActiveStaffPageState();
}

class _ActiveStaffPageState extends State<ActiveStaffPage> {
  final AdminService service = AdminService();

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: success ? Colors.green[700] : Colors.red[700],
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  List<dynamic> staffList = [];
  List<dynamic> filteredList = [];

  String searchText = "";
  bool isLoadingPage = true;
  bool _isLoading = false;

  // Track toggle loading for each staff ID
  Map<int, bool> toggleLoading = {};
  // Track reset password loading per staff ID
  Map<int, bool> resetLoading = {};

  @override
  void initState() {
    super.initState();
    loadStaff();
  }

  // ------------------------- LOAD STAFF ONLY ONCE ------------------------- //
  void loadStaff() async {
    setState(() => isLoadingPage = true);
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("userId") ?? "";

    final data = await service.getMedicalStaff();

    final nonAdmins = data
        .where(
          (s) =>
              s["role"].toString().toLowerCase() != "admin" &&
              s["user_Id"] != userId,
        )
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

  Future<void> resetPassword(int staffId) async {
    print('work $staffId'); // ✅ should print now
    setState(() {
      resetLoading[staffId] = true; // show loader immediately
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final String hospitalId = prefs.getString("hospitalId") ?? "";
      final String userId = prefs.getString("userId") ?? "";

      final response = await http.patch(
        Uri.parse('$baseUrl/auth/admin/reset_password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'hospitalId': hospitalId, 'userId': staffId}),
      );
      print('response ${response.body}');

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showMessage("✅ Password reset successful!", success: true);
      } else {
        _showMessage(data['message'] ?? "❌ Failed to reset password");
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage("❌ Error: $e");
    } finally {
      if (!mounted) return;
      setState(() {
        resetLoading[staffId] = false; // hide loader
      });
    }
  }

  void _confirmResetPassword(int staffId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔶 Icon
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFBF955E).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  size: 34,
                  color: Color(0xFFBF955E),
                ),
              ),

              const SizedBox(height: 16),

              // 📝 Title
              const Text(
                "Reset Password?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              // 📄 Description
              const Text(
                "Are you sure you want to reset this staff's password?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),

              const SizedBox(height: 12),

              // 🔑 Password highlight
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "New Password: abc123",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),

          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                // ❌ No button
                Expanded(
                  child: OutlinedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "No",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // ✅ Yes button
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      resetPassword(staffId);
                    },
                    child: const Text(
                      "Yes, Reset",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
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
                                  fontSize: 25,
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
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    "ID: ${staff['user_Id']}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  Text(
                                    "Role: ${staff['role']}",

                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.lock_reset_rounded,
                                        size: 16,
                                        color: Color(0xFFBF955E),
                                      ),

                                      const SizedBox(width: 1),

                                      // ✅ Reset Button / Loading
                                      resetLoading[staff["id"]] == true
                                          ? const Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 4,
                                              ),
                                              child: Text(
                                                "Loading...",
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFFBF955E),
                                                ),
                                              ),
                                            )
                                          : GestureDetector(
                                              onTap: () {
                                                // Initialize map if null
                                                if (resetLoading[staff["id"]] ==
                                                    null) {
                                                  resetLoading[staff["id"]] =
                                                      false;
                                                }
                                                //resetPassword(staff["id"]);
                                                _confirmResetPassword(
                                                  staff["id"],
                                                );
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.all(4),
                                                child: Text(
                                                  "Reset Password",
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFFBF955E),
                                                  ),
                                                ),
                                              ),
                                            ),
                                    ],
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
