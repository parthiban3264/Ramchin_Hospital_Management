import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AdministratorHome extends StatefulWidget {
  final Map<String, dynamic> hospitalData;

  const AdministratorHome({super.key, required this.hospitalData});

  @override
  State<AdministratorHome> createState() => _AdministratorHomeState();
}

class _AdministratorHomeState extends State<AdministratorHome> {
  int totalAdmins = 0;
  int totalDoctors = 0;
  int totalStaff = 0;

  @override
  void initState() {
    super.initState();
    calculateStats();
  }

  void calculateStats() {
    final admins = widget.hospitalData["Admins"] ?? [];

    int adminCount = 0;
    int doctorCount = 0;
    int staffCount = 0;
    int patientCount = 0;

    for (var a in admins) {
      final role = (a["role"] ?? "").toString().toLowerCase();
      final desi = (a["designation"] ?? "").toString().toLowerCase();

      if (role == "admin") {
        adminCount++;
      } else if (desi == "doctor") {
        doctorCount++;
      } else if (desi != "doctor") {
        staffCount++;
      }
      // else {
      //   patientCount++;
      // }
    }

    setState(() {
      totalAdmins = adminCount;
      totalDoctors = doctorCount;
      totalStaff = staffCount;
    });
  }

  // ---------------------------
  // STAT CARD WIDGET
  // ---------------------------
  Widget statCard(String title, int value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: color),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Text(
            "$value",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------
  // PIE CHART FOR ROLES
  // ---------------------------
  Widget buildRolePieChart() {
    final total = totalAdmins + totalDoctors + totalStaff;

    // If no data, show simple message
    if (total == 0) {
      return Center(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bar_chart, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                "No Data",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 40,
        sections: [
          if (totalAdmins > 0)
            PieChartSectionData(
              color: Colors.green,
              value: totalAdmins.toDouble(),
              title: "Admins",
              radius: 55,
              titleStyle: TextStyle(color: Colors.white, fontSize: 12),
            ),
          if (totalDoctors > 0)
            PieChartSectionData(
              color: Colors.red,
              value: totalDoctors.toDouble(),
              title: "Doctors",
              radius: 55,
              titleStyle: TextStyle(color: Colors.white, fontSize: 12),
            ),
          if (totalStaff > 0)
            PieChartSectionData(
              color: Colors.orange,
              value: totalStaff.toDouble(),
              title: "Staff",
              radius: 55,
              titleStyle: TextStyle(color: Colors.white, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget buildBarChart() {
    final total = totalAdmins + totalDoctors + totalStaff;

    // Show "No Data" if everything is 0
    if (total == 0) {
      return Center(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bar_chart, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                "No Data",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Otherwise, show the BarChart
    return BarChart(
      BarChartData(
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0:
                    return Text("Admins");
                  case 1:
                    return Text("Doctors");
                  case 2:
                    return Text("Staff");
                  default:
                    return Text("");
                }
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: totalAdmins.toDouble(),
                width: 25,
                color: Colors.green,
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: totalDoctors.toDouble(),
                width: 25,
                color: Colors.red,
              ),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(
                toY: totalStaff.toDouble(),
                width: 25,
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------
  // MAIN UI
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    final hospital = widget.hospitalData;
    // Copy this BEFORE ListView.builder
    final List admins = List.from(hospital["Admins"] ?? []);

    // Sorting priority:
    // 1. ADMIN
    // 2. Doctor
    // 3. Medical Staff
    // 4. Others
    admins.sort((a, b) {
      int getPriority(Map item) {
        if (item["role"] == "ADMIN") return 1;
        if (item["designation"].toString().toLowerCase() == "doctor") return 2;
        if (item["designation"].toString().toLowerCase() == "nurse") return 3;
        if (item["role"] == "Medical Staff") return 4;
        return 4;
      }

      return getPriority(a).compareTo(getPriority(b));
    });

    return Scaffold(
      // appBar: AppBar(
      //   title: Text(hospital["name"] ?? "Hospital Dashboard"),
      //   backgroundColor: Color(0xFFC59A62),
      // ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- STAT CARDS ----------------
            Row(
              children: [
                Expanded(
                  child: statCard(
                    "Admins",
                    totalAdmins,
                    Icons.admin_panel_settings,
                    Colors.green,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: statCard(
                    "Doctors",
                    totalDoctors,
                    Icons.medical_services,
                    Colors.red,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: statCard(
                    "Staff",
                    totalStaff,
                    Icons.people,
                    Colors.orange,
                  ),
                ),
              ],
            ),

            SizedBox(height: 30),

            // ---------------- PIE CHART ----------------
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 10.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.incomplete_circle, color: Color(0xFFC59A62)),
                    SizedBox(width: 10),
                    Text(
                      "Role Distribution",
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

            SizedBox(height: 12),
            SizedBox(height: 220, child: buildRolePieChart()),

            SizedBox(height: 30),

            // ---------------- BAR CHART ----------------
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 10.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, color: Color(0xFFC59A62)),
                    SizedBox(width: 10),
                    Text(
                      "Role Overview",
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
            SizedBox(height: 12),
            SizedBox(height: 240, child: buildBarChart()),

            SizedBox(height: 30),

            // ---------------- STAFF LIST ----------------
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 10.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.library_books_sharp, color: Color(0xFFC59A62)),
                    SizedBox(width: 10),
                    Text(
                      "Staff Members",
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
            SizedBox(height: 12),

            admins.isEmpty
                ? Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 30,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_off, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            "No Members Found",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: admins.length,
                    itemBuilder: (context, i) {
                      final a = admins[i];

                      // Colors based on role
                      Color roleColor = Colors.blueGrey;
                      if (a["role"] == "ADMIN") roleColor = Colors.green;
                      if (a["designation"].toString().toLowerCase() ==
                          "doctor") {
                        roleColor = Colors.red;
                      }
                      if (a["role"] == "Medical Staff" &&
                          a["designation"].toString().toLowerCase() !=
                              "doctor") {
                        roleColor = Colors.orange;
                      }

                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.grey.shade100],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Profile Icon
                            Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: roleColor.withOpacity(0.15),
                              ),
                              child: Icon(
                                Icons.person,
                                color: roleColor,
                                size: 28,
                              ),
                            ),
                            SizedBox(width: 16),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a["name"],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    a["designation"],
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: roleColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                a["role"],
                                style: TextStyle(
                                  fontSize: 12,
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
