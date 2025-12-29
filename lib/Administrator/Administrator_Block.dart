import 'package:flutter/material.dart';
import 'package:hospitrax/Admin/Pages/AdminEditProfilePage.dart';

import '../Pages/NotificationsPage.dart';
import '../Services/hospital_Service.dart';
import 'Overall_Administrator_Dashboard.dart';

class AdministratorBlock extends StatefulWidget {
  final Map<String, dynamic> hospitalData;
  final VoidCallback? onHospitalUpdated;

  const AdministratorBlock({
    super.key,
    required this.hospitalData,
    this.onHospitalUpdated,
  });

  @override
  State<AdministratorBlock> createState() => _AdministratorBlockState();
}

class _AdministratorBlockState extends State<AdministratorBlock> {
  final HospitalService hospitalService = HospitalService();
  bool isLoading = false;

  Map<String, dynamic> get hospital => widget.hospitalData;

  Future<void> toggleHospitalStatus() async {
    setState(() => isLoading = true);

    String newStatus = hospital["HospitalStatus"] == "ACTIVE"
        ? "INACTIVE"
        : "ACTIVE";

    bool success = await hospitalService.updateHospitals(hospital["id"], {
      "HospitalStatus": newStatus,
    });

    setState(() => isLoading = false);

    if (success) {
      setState(() {
        hospital["HospitalStatus"] = newStatus;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Hospital ${newStatus == "ACTIVE" ? "unblocked" : "blocked"} successfully!",
            ),
          ),
        );
      }
      widget.onHospitalUpdated?.call();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update hospital status")),
        );
      }
    }
  }

  Future<void> deleteHospital() async {
    bool confirm = await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this hospital?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OverallAdministratorDashPage(),
                ),
              ),
              // widget.onHospitalUpdated?.call(),
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (!confirm) return;

    setState(() => isLoading = true);
    bool success = await hospitalService.deleteHospital(hospital["id"]);
    setState(() => isLoading = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Hospital deleted successfully!")),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete hospital")),
        );
      }
    }
  }

  // Sort Admins by priority: Admin > Doctor > Staff > Others
  List<dynamic> getSortedAdmins() {
    if (hospital["Admins"] == null) return [];
    List<dynamic> admins = List.from(hospital["Admins"]);

    int getPriority(Map admin) {
      String role = admin["role"].toString().toLowerCase();
      String designation = admin["designation"].toString().toLowerCase();
      if (role == "admin") return 1;
      if (role == "medical staff" && designation == "doctor") return 2;
      if (designation == "nurse") return 3;
      if (designation == "lab") return 4;
      if (designation == "cashier") return 5;
      if (role == "medical staff") return 6;
      return 7;
    }

    admins.sort((a, b) => getPriority(a).compareTo(getPriority(b)));
    return admins;
  }

  @override
  Widget build(BuildContext context) {
    // Color statusColor = hospital["HospitalStatus"] == "ACTIVE"
    //     ? Colors.green
    //     : Colors.red;

    List<dynamic> admins = getSortedAdmins();

    return Scaffold(
      appBar: PreferredSize(
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
                  const Spacer(),
                  const Text(
                    "Hospital Management",
                    overflow: TextOverflow.ellipsis,
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hospital Info Card
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ), // border
                    ),
                    color: Colors.white.withValues(
                      alpha: 0.95,
                    ), // subtle card color
                    elevation: 8,
                    shadowColor: Colors.black26,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Hospital Image with border
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundImage: NetworkImage(
                                hospital["photo"] ?? "",
                              ),
                              backgroundColor: Colors.grey.shade200,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Hospital Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Hospital Name
                                Text(
                                  hospital["name"] ?? "Unknown Hospital",
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),

                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    SizedBox(width: 3),
                                    // Card(
                                    //   elevation: 2,
                                    //   // margin: EdgeInsets.symmetric(
                                    //   //   vertical: 5,
                                    //   //   horizontal: 10,
                                    //   // ),
                                    //   child: Padding(
                                    //     padding: EdgeInsets.symmetric(
                                    //       horizontal: 12,
                                    //       vertical: 3,
                                    //     ), // add space inside the card
                                    //     child: Text(
                                    //       'ID : ${hospital["id"].toString()}',
                                    //       style: TextStyle(
                                    //         fontSize: 15,
                                    //         color: Colors.black87,
                                    //       ),
                                    //     ),
                                    //   ),
                                    // ),
                                    Text(
                                      'ID : ${hospital["id"].toString()}',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Spacer(),
                                    // Status Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors:
                                              hospital["HospitalStatus"] ==
                                                  "ACTIVE"
                                              ? [
                                                  Colors.green.shade400,
                                                  Colors.green.shade700,
                                                ]
                                              : [
                                                  Colors.red.shade400,
                                                  Colors.red.shade700,
                                                ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        hospital["HospitalStatus"] ?? "UNKNOWN",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                // Hospital Address
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        hospital["address"] ??
                                            "Unknown Address",
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
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
                  ),

                  const SizedBox(height: 20),

                  // Block/Unblock and Delete Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(
                          hospital["HospitalStatus"] == "ACTIVE"
                              ? Icons.block
                              : Icons.check_circle,
                          color: Colors.white,
                        ),
                        label: Text(
                          hospital["HospitalStatus"] == "ACTIVE"
                              ? "Block"
                              : "Unblock",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              hospital["HospitalStatus"] == "ACTIVE"
                              ? Colors.orange
                              : Colors.green,
                        ),
                        onPressed: toggleHospitalStatus,
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        label: const Text(
                          "Delete",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: deleteHospital,
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Admin List
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14.0,
                        horizontal: 10.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            color: Color(0xFFC59A62),
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Hospital Members List ",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  admins.isEmpty
                      ? Center(
                          child: Text(
                            "No Members Found",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: admins.length,
                          itemBuilder: (context, index) {
                            // Sort admins by role priority: Admin -> Doctor -> Staff -> Others
                            admins.sort((a, b) {
                              int getPriority(Map item) {
                                String role = item["role"]
                                    .toString()
                                    .toLowerCase();
                                String designation = item["designation"]
                                    .toString()
                                    .toLowerCase();

                                if (role == "admin") return 1;
                                if (role == "medical staff" &&
                                    designation == "doctor") {
                                  return 2;
                                }
                                if (designation == "nurse") return 3;
                                if (designation == "lab") return 4;
                                if (designation == "cashier") return 5;
                                if (role == "medical staff") return 6;
                                return 7; // fallback for others
                              }

                              return getPriority(a).compareTo(getPriority(b));
                            });

                            final admin = admins[index];
                            Color roleColor = Colors.blueGrey;

                            String role = admin["role"]
                                .toString()
                                .toLowerCase();
                            String designation = admin["designation"]
                                .toString()
                                .toLowerCase();

                            // Role-based colors
                            if (role == "admin") {
                              roleColor = Colors.green;
                            } else if (role == "medical staff" &&
                                designation == "doctor") {
                              roleColor = Colors.red;
                            } else if (designation == "nurse") {
                              roleColor = Colors.purple;
                            } else if (designation == "lab") {
                              roleColor = Colors.teal;
                            } else if (designation == "cashier") {
                              roleColor = Colors.blue;
                            } else if (role == "medical staff") {
                              roleColor = Colors.orange;
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: roleColor.withValues(
                                      alpha: 0.2,
                                    ),
                                    child: Icon(Icons.person, color: roleColor),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          admin["name"] ?? "Unknown",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(admin["designation"] ?? ""),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: roleColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      admin["role"] ?? "",
                                      style: TextStyle(
                                        color: roleColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}
