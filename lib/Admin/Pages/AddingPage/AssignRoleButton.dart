import 'package:flutter/material.dart';

import '../../../Services/Button_Service.dart';
import '../../../Services/admin_service.dart';

// ------------------- MAIN SCREEN -------------------
class AssignRoleButton extends StatefulWidget {
  const AssignRoleButton({super.key});

  @override
  State<AssignRoleButton> createState() => _AssignRoleButtonState();
}

class _AssignRoleButtonState extends State<AssignRoleButton> {
  bool loading = true;
  List<dynamic> staff = [];
  List<dynamic> doctor = [];
  List<dynamic> permissions = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ---------------- LOAD ALL STAFF + ALL PERMISSIONS + STAFF SAVED PERMISSIONS ----------------
  Future<void> loadData() async {
    try {
      final staffData = await AdminService().getMedicalStaff();
      final permData = await ButtonPermissionService().getAllByHospital();

      // Remove Admin / Super Admin
      final filteredStaff = (staffData).where((user) {
        final role = (user["role"] ?? "").toString().toLowerCase();
        final status = (user["status"] ?? "").toString().toLowerCase();
        return role != "admin" && status != "inactive";
      }).toList();

      final filteredDoctor = (staffData).where((user) {
        final role = (user["role"] ?? "").toString().toLowerCase() == "doctor";
        return role;
      }).toList();

      // ✅ Assign permissions ID list for each staff
      for (var user in filteredStaff) {
        final List<dynamic> permList = user["permissions"] ?? [];

        user["assignedPermissionIds"] = permList
            .map<int>((e) => e as int)
            .toList();
        // ✅ ADD THIS
        user["assignedDoctorId"] = user["assignDoctorId"];
      }

      setState(() {
        staff = filteredStaff;
        doctor = filteredDoctor;
        permissions = permData;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  // ---------------- GROUP STAFF BY DESIGNATION ----------------
  Map<String, List<dynamic>> groupByDesignation() {
    Map<String, List<dynamic>> map = {};
    for (var user in staff) {
      String des = (user["role"] ?? "").toString().toLowerCase();
      if (!map.containsKey(des)) map[des] = [];
      map[des]!.add(user);
    }
    return map;
  }

  // ---------------- SORT DESIGNATIONS ----------------
  List<String> getSortedDesignations(Map<String, List<dynamic>> grouped) {
    List<String> order = [
      "doctor",
      "assistant doctor",
      "nurse",
      "cashier",
      "medical staff",
      "lab technician",
      "non-medical staff",
    ];
    List<String> keys = grouped.keys
        .map((k) => order.contains(k) ? k : "")
        .toSet()
        .toList();
    keys.sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));
    return keys;
  }

  @override
  Widget build(BuildContext context) {
    final groupedStaff = groupByDesignation();
    final sortedKeys = getSortedDesignations(groupedStaff);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFBF955E),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
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
                    "Assign Duty",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : staff.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.group_off_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "No Staff Found",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF444444),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Please add staff members first to assign role buttons and permissions.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: sortedKeys.length,
              itemBuilder: (context, index) {
                String designation = sortedKeys[index];
                List<dynamic> users = groupedStaff[designation] ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 8,
                        top: 20,
                        bottom: 8,
                      ),
                      child: designation != 'Lab'
                          ? Text(
                              designation.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF444444),
                              ),
                            )
                          : const Text(
                              'LAB TECHNICIAN',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF444444),
                              ),
                            ),
                    ),

                    // ---------- STAFF LIST ----------
                    ...users.map((user) {
                      final specialist = (user["specialist"] ?? "").toString();

                      // final filteredPermissions = permissions
                      //     .where(
                      //       (p) =>
                      //           (p["designation"] ?? "").toString() ==
                      //           designation,
                      //     )
                      //     .toList();

                      final filteredPermissions = designation == "admin"
                          ? permissions
                                .where(
                                  (p) =>
                                      (p["designation"] ?? "").toString() ==
                                      "doctor",
                                )
                                .toList()
                          : permissions
                                .where(
                                  (p) =>
                                      (p["designation"] ?? "").toString() ==
                                      designation,
                                )
                                .toList();
                      final filteredAdmins = staff
                          .where(
                            (u) =>
                                (u["role"] ?? "").toString().toLowerCase() ==
                                "admin",
                          )
                          .toList();
                      final anyAdminAccessDoctorRole = staff.any(
                        (u) =>
                            (u["role"] ?? "").toString().toLowerCase() ==
                                "admin" &&
                            (u["accessDoctorRole"] ?? false) == true,
                      );

                      return StaffPermissionTile(
                        id: user["id"],
                        name: user["fullName"] ?? user["name"] ?? "Unnamed",
                        designation: designation,
                        specialist: specialist,
                        permissions: filteredPermissions,
                        assignedPermissionIds:
                            user["assignedPermissionIds"], // 🔥 FIX
                        doctorList: doctor, // ✅ ADD THIS
                        adminList: filteredAdmins, // ✅ pass admin list
                        assignedDoctorId: user["assignedDoctorId"], // ✅ ADD
                        accessDoctorRole: designation == "admin"
                            ? (user["accessDoctorRole"] ??
                                  false) // ✅ use individual value
                            : anyAdminAccessDoctorRole, // for assistant doctor
                        onAdminAccessChanged: () {
                          setState(() {
                            // 🔥 Update local staff data immediately
                            user["accessDoctorRole"] =
                                !user["accessDoctorRole"];
                          });
                        },

                        // ✅ ADD THIS FOR DOCTOR
                        accessAdminRole: user["accessAdminRole"] ?? false,

                        // onAdminAccessChanged: () async {
                        //   setState(() => loading = true);
                        //   await loadData(); // 🔥 FULL REFRESH
                        // },
                      );
                    }),
                  ],
                );
              },
            ),
    );
  }
}

// ===========================================================
//  STAFF TILE WITH SWITCHES + SAVED STATE
// ===========================================================

class StaffPermissionTile extends StatefulWidget {
  final int id;
  final String name;
  final String designation;
  final String specialist;
  final List<dynamic> permissions;
  final List<dynamic> doctorList;
  final String? assignedDoctorId;
  final bool accessDoctorRole;
  final List<dynamic> adminList; // new field
  final VoidCallback onAdminAccessChanged;
  final bool accessAdminRole;

  // NEW FIELD
  final List<int> assignedPermissionIds;

  const StaffPermissionTile({
    super.key,
    required this.id,
    required this.name,
    required this.designation,
    required this.specialist,
    required this.permissions,
    required this.assignedPermissionIds,
    required this.doctorList,
    this.assignedDoctorId,
    required this.accessDoctorRole,
    required this.adminList,
    required this.onAdminAccessChanged,
    required this.accessAdminRole,
  });

  @override
  State<StaffPermissionTile> createState() => _StaffPermissionTileState();
}

class _StaffPermissionTileState extends State<StaffPermissionTile>
    with SingleTickerProviderStateMixin {
  Map<int, bool> toggles = {};
  bool expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _animation;
  String? selectedDoctorId;
  bool accessDoctorRole = false;
  bool accessAdminRole = false;

  @override
  void initState() {
    super.initState();
    buildToggleMap(); // 🔥 LOAD SAVED PERMISSIONS
    // ✅ THIS FIXES YOUR ISSUE
    if (widget.designation == "assistant doctor") {
      selectedDoctorId = widget.assignedDoctorId;
    }

    // ✅ Load saved admin access for doctor
    if (widget.designation == "doctor") {
      accessAdminRole = widget.accessAdminRole;
    }
    // ✅ FIX: load saved accessDoctorRole
    if (widget.designation == "admin") {
      accessDoctorRole = widget.accessDoctorRole;
    }
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  void buildToggleMap() {
    toggles = {
      for (var perm in widget.permissions)
        perm["id"] as int: widget.assignedPermissionIds.contains(
          perm["id"],
        ), // 🔥 FIX
    };
  }

  Future<void> updateToggle(int permId, bool value) async {
    setState(() => toggles[permId] = value);

    try {
      List<int> enabledIds = toggles.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      await AdminService().updateAdminAmount(widget.id, {
        "permissions": enabledIds,
      });

      // 🔥 UPDATE LOCAL STAFF PERMISSION LIST
      widget.assignedPermissionIds
        ..clear()
        ..addAll(enabledIds);
    } catch (e) {
      setState(() => toggles[permId] = !value);
    }
  }

  Future<void> updateDoctorSelection(String doctorId) async {
    setState(() => selectedDoctorId = doctorId.isEmpty ? null : doctorId);

    try {
      await AdminService().updateAdminAmount(widget.id, {
        "assignDoctorId": doctorId.isEmpty ? null : doctorId,
      });
    } catch (e) {
      setState(() => selectedDoctorId = null);
    }
  }

  Future<void> updateDoctorAccess(bool value) async {
    setState(() => accessDoctorRole = value);

    try {
      await AdminService().updateAdminAmount(widget.id, {
        "accessDoctorRole": value,
      });
      widget.onAdminAccessChanged();
    } catch (e) {
      setState(() => accessDoctorRole = !value);
    }
  }

  Future<void> updateAdminAccess(bool value) async {
    setState(() => accessAdminRole = value);

    try {
      await AdminService().updateAdminAmount(widget.id, {
        "accessAdminRole": value,
      });

      widget.onAdminAccessChanged();
    } catch (e) {
      setState(() => accessAdminRole = !value);
    }
  }

  void toggleExpand() {
    setState(() {
      expanded = !expanded;

      if (expanded) {
        buildToggleMap(); // 🔥 Refresh state when opening
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 5,
          shadowColor: Colors.black26,
          child: Column(
            children: [
              InkWell(
                onTap: toggleExpand,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade50, Colors.orange.shade100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.orange.shade300,
                        child: Text(
                          widget.name.isNotEmpty
                              ? widget.name[0].toUpperCase()
                              : "?",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF222222),
                              ),
                            ),
                            if (widget.specialist.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  widget.specialist,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: expanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.grey,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ------------- EXPANDED PERMISSION LIST -------------
              SizeTransition(
                sizeFactor: _animation,
                axisAlignment: -1.0,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  // child: widget.designation == "assistant doctor"
                  //     ? buildDoctorSelector()
                  //     : buildPermissionToggles(),
                  //   child: widget.designation == "assistant doctor"
                  //       ? buildDoctorSelector()
                  //       : widget.designation == "admin"
                  //       ? buildAdminDoctorAccess()
                  //       : buildPermissionToggles(),
                  // ),
                  child: widget.designation == "assistant doctor"
                      ? buildDoctorSelector()
                      : widget.designation == "admin"
                      ? buildAdminDoctorAccess()
                      : widget.designation == "doctor"
                      ? buildDoctorAdminAccess()
                      : buildPermissionToggles(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget buildDoctorSelector() {
  //   if (widget.doctorList.isEmpty) {
  //     return const Text(
  //       "No doctors available",
  //       style: TextStyle(color: Colors.redAccent),
  //     );
  //   }
  //
  //   return Column(
  //     children: widget.doctorList.map((doc) {
  //       final String docId = doc["user_Id"];
  //       final bool isSelected = selectedDoctorId == docId;
  //
  //       return Padding(
  //         padding: const EdgeInsets.symmetric(vertical: 6),
  //         child: Row(
  //           children: [
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     doc["name"] ?? "Doctor",
  //                     style: const TextStyle(
  //                       fontSize: 15,
  //                       fontWeight: FontWeight.w600,
  //                     ),
  //                   ),
  //                   Text(
  //                     doc["specialist"] ?? "Doctor",
  //                     style: const TextStyle(
  //                       color: Colors.black54,
  //                       fontStyle: FontStyle.italic,
  //                       fontSize: 15,
  //                       fontWeight: FontWeight.w400,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             Switch(
  //               value: isSelected,
  //               activeColor: Colors.green,
  //               inactiveThumbColor: Colors.redAccent,
  //               onChanged: (val) {
  //                 if (val) {
  //                   updateDoctorSelection(docId);
  //                 } else {
  //                   updateDoctorSelection(""); // 🔥 clear selection
  //                 }
  //               },
  //             ),
  //           ],
  //         ),
  //       );
  //     }).toList(),
  //   );
  // }

  Widget buildDoctorSelector() {
    if (widget.doctorList.isEmpty && widget.adminList.isEmpty) {
      return const Text(
        "No doctors available",
        style: TextStyle(color: Colors.redAccent),
      );
    }

    // Combine admin + doctor list if any admin has accessDoctorRole
    // final List<dynamic> selectableDoctors = [
    //   if (widget.accessDoctorRole) ...widget.adminList,
    //   ...widget.doctorList,
    // ];
    final List<dynamic> selectableDoctors = [
      ...widget.adminList.where(
        (a) => a["accessDoctorRole"] == true,
      ), // only admins with access
      ...widget.doctorList,
    ];

    return Column(
      children: selectableDoctors.map((doc) {
        final String docId = doc["user_Id"];
        final bool isSelected = selectedDoctorId == docId;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc["name"] ?? "Doctor",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      doc["specialist"] ?? "",
                      style: const TextStyle(
                        color: Colors.black54,
                        fontStyle: FontStyle.italic,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isSelected,
                activeColor: Colors.green,
                inactiveThumbColor: Colors.redAccent,
                onChanged: (val) {
                  if (val) {
                    updateDoctorSelection(docId);
                  } else {
                    updateDoctorSelection(""); // clear selection
                  }
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget buildPermissionToggles() {
    if (widget.permissions.isEmpty) {
      return const Text(
        "No button assigned for this staff",
        style: TextStyle(color: Colors.redAccent),
      );
    }

    return Column(
      children: toggles.entries.map((entry) {
        final permId = entry.key;
        final enabled = entry.value;

        final permKey = widget.permissions
            .firstWhere((p) => p["id"] == permId)["key"]
            .toString()
            .toUpperCase();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(child: Text(permKey)),
              Switch(
                value: enabled,
                activeColor: Colors.green,
                inactiveThumbColor: Colors.redAccent,
                onChanged: (val) => updateToggle(permId, val),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget buildAdminDoctorAccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Access toggle
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  "ACCESS DOCTOR ROLE",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Switch(
                value: accessDoctorRole,
                activeColor: Colors.green,
                inactiveThumbColor: Colors.redAccent,
                onChanged: updateDoctorAccess,
              ),
            ],
          ),
        ),

        // ✅ Show doctor permissions only if enabled
        if (accessDoctorRole) ...[const Divider(), buildPermissionToggles()],
      ],
    );
  }

  Widget buildDoctorAdminAccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  "ACCESS ADMIN ROLE",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Switch(
                value: accessAdminRole,
                activeColor: Colors.green,
                inactiveThumbColor: Colors.redAccent,
                onChanged: updateAdminAccess,
              ),
            ],
          ),
        ),

        // ✅ ALWAYS show permissions (no condition)
        const Divider(),
        buildPermissionToggles(),
      ],
    );
  }
}
