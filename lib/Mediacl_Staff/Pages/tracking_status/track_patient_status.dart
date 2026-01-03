import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hospitrax/Mediacl_Staff/Pages/tracking_status/patient_tracking_details_page.dart';
import '../../../Services/consultation_service.dart';

const Color primaryColor = Color(0xFFBF955E);

class TrackingPatientStatus extends StatefulWidget {
  const TrackingPatientStatus({super.key});

  @override
  State<TrackingPatientStatus> createState() => _TrackingPatientStatusState();
}

class _TrackingPatientStatusState extends State<TrackingPatientStatus> {
  late Future<List<dynamic>> consultationsFuture;
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    consultationsFuture = ConsultationService().getAllConsultations();
  }

  /// ✅ CHECK TODAY DATE
  bool isToday(String dateString) {
    try {
      DateTime date;
      if (dateString.contains('AM') || dateString.contains('PM')) {
        date = DateFormat("yyyy-MM-dd hh:mm a").parse(dateString);
      } else {
        date = DateTime.parse(dateString);
      }

      final now = DateTime.now();
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    } catch (_) {
      return false;
    }
  }

  Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'ONGOING':
        return Colors.blue;
      case 'CANCELLED':
        return Colors.red;
      case 'ENDPROCEEDING':
        return Colors.purple;
      case 'COMPLETED':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      /// 🔹 APP BAR
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
                  const Text(
                    "Track Patients",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      /// 🔹 BODY
      body: FutureBuilder<List<dynamic>>(
        future: consultationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final data = snapshot.data ?? [];

          /// 🔹 FILTER LOGIC (IMPORTANT)
          final filteredList = data.where((item) {
            final status = (item['status'] ?? '').toString().toUpperCase();
            final createdAt = item['createdAt'] ?? '';
            final patient = item['Patient'] ?? {};
            final name = patient['name']?.toString().toLowerCase() ?? '';
            final id = patient['id']?.toString() ?? '';

            final matchesSearch =
                searchQuery.isNotEmpty &&
                (name.contains(searchQuery.toLowerCase()) ||
                    id.contains(searchQuery));

            /// 🔍 SEARCH MODE → show all matching (any date, any status)
            if (searchQuery.isNotEmpty) {
              return matchesSearch;
            }

            /// 🚫 DEFAULT MODE → hide completed
            if (status == 'COMPLETED') return false;

            /// ✅ DEFAULT MODE → show only today's consultations
            return isToday(createdAt);
          }).toList();

          return Column(
            children: [
              /// 🔍 SEARCH BAR
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: (v) => setState(() => searchQuery = v),
                  decoration: InputDecoration(
                    hintText: "Search by Patient ID or Name",
                    prefixIcon: const Icon(Icons.search, color: primaryColor),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              /// 🔹 LIST
              Expanded(
                child: filteredList.isEmpty
                    ? const Center(
                        child: Text(
                          "No patients found",
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final item = filteredList[index];
                          final patient = item['Patient'] ?? {};
                          final status = item['status'] ?? '';

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: primaryColor.withOpacity(0.15),
                                child: Text(
                                  "${item['tokenNo'] ?? '-'}", // Show token number here
                                  style: const TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                patient['name'] ?? "Unknown",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                "Patient ID: ${patient['id'] ?? '-'}",
                              ),
                              trailing: _statusChip(
                                status.toString().toUpperCase(),
                                statusColor(status),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PatientTrackingDetailsPage(
                                      consultation: item,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 🔹 STATUS CHIP
  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
