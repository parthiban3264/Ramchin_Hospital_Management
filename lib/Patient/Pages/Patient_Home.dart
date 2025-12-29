import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../Pages/DashboardPages/patient_dashboard.dart';

class PatientHome extends StatefulWidget {
  final Map<String, dynamic> hospitalData;

  const PatientHome({super.key, required this.hospitalData});

  @override
  State<PatientHome> createState() => _PatientHomeState();
}

// final DateFormat myFormat = DateFormat("yyyy-MM-dd hh:mm a");
final DateFormat myFormat = DateFormat("yyyy-MM-dd HH:mm"); // 24-hour format

String timeAgoSafe(String? dateString) {
  if (dateString == null) return "";
  try {
    DateTime date = myFormat.parse(dateString);
    DateTime now = DateTime.now();
    Duration diff = now.difference(date);

    if (diff.inDays == 0) return "Today";
    if (diff.inDays == 1) return "Yesterday";
    return "${diff.inDays} days ago";
  } catch (e) {
    return "";
  }
}

DateTime? parseCreatedAt(String? createdAt) {
  if (createdAt == null) return null;
  try {
    return myFormat.parse(createdAt);
  } catch (e) {
    return null;
  }
}

class _PatientHomeState extends State<PatientHome> {
  Map<String, dynamic> localData = {};

  @override
  void initState() {
    super.initState();
    localData = widget.hospitalData;
  }

  Future<void> _refreshData() async {
    await PatientDashboardPage.of(context)?.refreshFromChild();
    setState(() {
      localData = PatientDashboardPage.of(context)?.hospitals ?? {};
    });
  }

  String getItemName(Map item, String type) {
    try {
      switch (type) {
        case 'medicine':
          return item['Medician']?['medicianName']?.toString() ??
              'Unknown medicine';
        case 'injection':
          return item['Injection']?['injectionName']?.toString() ??
              'Unknown injection';
        case 'tonic':
          return item['Tonic']?['tonicName']?.toString() ?? 'Unknown tonic';
        default:
          return 'Unknown';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Object getQty(Map item, String type) {
    try {
      switch (type) {
        case 'tonic':
          // Tonic uses 'Doase', can be int, string int, or string decimal
          if (item.containsKey('Doase')) {
            final doase = item['Doase'];
            if (doase is int) return doase;
            if (doase is double) return doase.toInt();
            if (doase is String) {
              final parsed = double.tryParse(doase);
              if (parsed != null) return '${parsed.toInt()} ml';
            }
          }
          break;
        case 'medicine':
        case 'injection':
        default:
          // Medicine and Injection use 'quantity'
          if (item.containsKey('quantity')) {
            if (item['quantity'] is int) return item['quantity'] as int;
            if (item['quantity'] is String) {
              return int.tryParse(item['quantity']) ?? 1;
            }
          }
          break;
      }
    } catch (_) {}
    return 1; // fallback
  }

  bool isOverItem(Map item) {
    if (item.containsKey('isOver')) {
      final v = item['isOver'];
      if (v is bool) return v;
      if (v is String) return v.toLowerCase() == 'true';
    }
    final status = (item['status'] ?? '').toString().toUpperCase();
    return status == 'COMPLETED' || status == 'DONE';
  }

  bool isCreatedToday(Map item) {
    final createdAt = item['createdAt'];
    if (createdAt == null) return false;

    try {
      final dt = myFormat.parse(createdAt.toString());
      final now = DateTime.now();

      // Compare ONLY day & month (ignore year mismatch)
      return dt.day == now.day && dt.month == now.month;
    } catch (e) {
      return false;
    }
  }

  List<Map<String, dynamic>> buildDisplayList(List<dynamic> raw, String type) {
    final List<Map<String, dynamic>> out = [];
    for (var r in raw) {
      if (r is! Map) continue;

      if (!isCreatedToday(r)) continue;
      final name = getItemName(r, type);
      final qty = getQty(r, type);
      final over = isOverItem(r);
      out.add({'name': name, 'qty': qty, 'isOver': over, 'raw': r});
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final hospital = localData;
    final patients = hospital['Patients'] ?? [];
    final consultation = hospital['Consultation'] ?? [];

    final medicineRaw = hospital['MedicinePatients'] ?? [];
    final injectionRaw = hospital['InjectionPatients'] ?? [];
    final tonicRaw = hospital['TonicPatients'] ?? [];

    final todayMedicine = buildDisplayList(medicineRaw, 'medicine');
    final todayInjection = buildDisplayList(injectionRaw, 'injection');
    final todayTonic = buildDisplayList(tonicRaw, 'tonic');

    Map<String, List<Map<String, dynamic>>> morning = {
      'Over': [],
      'Upcoming': [],
    };
    Map<String, List<Map<String, dynamic>>> afternoon = {
      'Over': [],
      'Upcoming': [],
    };
    Map<String, List<Map<String, dynamic>>> night = {
      'Over': [],
      'Upcoming': [],
    };

    void handleSessionPush(Map<String, dynamic> displayItem, Map rawItem) {
      if (rawItem['morning'] == true) {
        (displayItem['isOver'] == true ? morning['Over'] : morning['Upcoming'])!
            .add(displayItem);
      }
      if (rawItem['afternoon'] == true) {
        (displayItem['isOver'] == true
                ? afternoon['Over']
                : afternoon['Upcoming'])!
            .add(displayItem);
      }
      if (rawItem['night'] == true) {
        (displayItem['isOver'] == true ? night['Over'] : night['Upcoming'])!
            .add(displayItem);
      }
    }

    for (var m in medicineRaw) {
      if (m is! Map) continue;
      if (!isCreatedToday(m)) continue;
      handleSessionPush({
        'name': getItemName(m, 'medicine'),
        'qty': getQty(m, 'medicine'),
        'isOver': isOverItem(m),
        'raw': m,
      }, m);
    }
    for (var inj in injectionRaw) {
      if (inj is! Map) continue;
      if (!isCreatedToday(inj)) continue;
      handleSessionPush({
        'name': getItemName(inj, 'injection'),
        'qty': getQty(inj, 'injection'),
        'isOver': isOverItem(inj),
        'raw': inj,
      }, inj);
    }
    for (var t in tonicRaw) {
      if (t is! Map) continue;
      if (!isCreatedToday(t)) continue;
      handleSessionPush({
        'name': getItemName(t, 'tonic'),
        'qty': getQty(t, 'tonic'),
        'isOver': isOverItem(t),
        'raw': t,
      }, t);
    }

    Map<String, dynamic>? selected;
    try {
      selected = (consultation as List).firstWhere(
        (c) => (c?['status'] ?? '') == 'PENDING',
        orElse: () => null,
      );
    } catch (_) {
      selected = null;
    }
    if (selected == null) {
      try {
        selected = (consultation as List).firstWhere(
          (c) => (c?['status'] ?? '') == 'ONGOING',
          orElse: () => null,
        );
      } catch (_) {
        selected = null;
      }
    }
    if (selected == null) {
      try {
        selected = (consultation as List).firstWhere(
          (c) => (c?['status'] ?? '') == 'ENDPROCESSING',
          orElse: () => null,
        );
      } catch (_) {
        selected = null;
      }
    }
    if (selected == null) {
      try {
        final completed = (consultation as List)
            .where((c) => (c?['status'] ?? '') == 'COMPLETED')
            .toList();
        completed.sort((a, b) {
          final pa = parseCreatedAt(a?['createdAt']);
          final pb = parseCreatedAt(b?['createdAt']);
          if (pa == null || pb == null) return 0;
          return pb.compareTo(pa); // recent first
        });
        if (completed.isNotEmpty) selected = completed.first;
      } catch (_) {
        selected = null;
      }
    }

    // final now = DateTime.now();
    // final hour = now.hour;

    // bool showMorning =
    //     hour < 11 &&
    //     (morning['Over']!.isNotEmpty || morning['Upcoming']!.isNotEmpty);
    // bool showAfternoon =
    //     hour >= 11 &&
    //     hour < 16 &&
    //     (afternoon['Over']!.isNotEmpty || afternoon['Upcoming']!.isNotEmpty);
    // bool showNight =
    //     hour >= 16 &&
    //     (night['Over']!.isNotEmpty || night['Upcoming']!.isNotEmpty);
    bool showMorning =
        morning['Over']!.isNotEmpty || morning['Upcoming']!.isNotEmpty;
    bool showAfternoon =
        afternoon['Over']!.isNotEmpty || afternoon['Upcoming']!.isNotEmpty;
    bool showNight = night['Over']!.isNotEmpty || night['Upcoming']!.isNotEmpty;

    // bool showMorning =
    //     hour < 11 &&
    //     (morning['Over']!.isNotEmpty || morning['Upcoming']!.isNotEmpty);
    // bool showAfternoon =
    //     hour >= 11 &&
    //     hour < 16 &&
    //     (afternoon['Over']!.isNotEmpty || afternoon['Upcoming']!.isNotEmpty);
    // bool showNight =
    //     hour >= 16 &&
    //     (night['Over']!.isNotEmpty || night['Upcoming']!.isNotEmpty);

    Widget sessionCard(
      String sessionTitle,
      Map<String, List<Map<String, dynamic>>> sessionData,
    ) {
      final over = sessionData['Over']!;
      final upcoming = sessionData['Upcoming']!;
      final any = over.isNotEmpty || upcoming.isNotEmpty;

      final overCount = over.length;
      final upcomingCount = upcoming.length;

      return Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ExpansionTile(
          initiallyExpanded: any,
          title: Row(
            children: [
              Icon(
                sessionTitle == 'Morning'
                    ? Icons.wb_sunny
                    : sessionTitle == 'Afternoon'
                    ? Icons.wb_sunny_outlined
                    : Icons.nights_stay,
                color: Colors.teal,
              ),
              const SizedBox(width: 12),
              Text(
                sessionTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              if (!any)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'No meds',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              const Spacer(),
              if (upcomingCount > 0)
                _countBadge(
                  '$upcomingCount',
                  Colors.orange.shade100,
                  Colors.orange.shade800,
                ),
              const SizedBox(width: 6),
              if (overCount > 0)
                _countBadge(
                  '$overCount',
                  Colors.green.shade100,
                  Colors.green.shade800,
                ),
            ],
          ),
          children: [
            if (upcoming.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...upcoming.map((it) => _medRow(it, false)).toList(),
                  ],
                ),
              ),
            if (over.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [...over.map((it) => _medRow(it, true)).toList()],
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    Widget upcomingBySessionSection(
      String sessionName,
      List<Map<String, dynamic>> items,
    ) {
      if (items.isEmpty) {
        return _emptyBox('No upcoming medication for $sessionName');
      }
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sessionName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 8),
              ...items.map(
                (it) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.medication, color: Colors.teal),
                  title: Text(it['name'] ?? 'Unknown'),
                  trailing: Text('Qty: ${it['qty']}'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final morningUpcoming = morning['Upcoming']!;
    final afternoonUpcoming = afternoon['Upcoming']!;
    final nightUpcoming = night['Upcoming']!;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 24, 12, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(hospital, patients),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Text(
                    "Today's Medication",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '(${todayMedicine.length + todayInjection.length + todayTonic.length})',
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (showMorning) sessionCard('Morning', morning),
              if (showAfternoon) sessionCard('Afternoon', afternoon),
              if (showNight) sessionCard('Night', night),
              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 8),
              _sectionTitle('Tomorrow Medication'),
              const SizedBox(height: 8),
              if (morningUpcoming.isNotEmpty)
                upcomingBySessionSection('Morning', morningUpcoming),
              if (afternoonUpcoming.isNotEmpty)
                upcomingBySessionSection('Afternoon', afternoonUpcoming),
              if (nightUpcoming.isNotEmpty)
                upcomingBySessionSection('Night', nightUpcoming),
              const SizedBox(height: 20),
              _sectionTitle('Recent Consultation'),
              const SizedBox(height: 12),
              if (selected == null) _emptyBox('No recent consultations'),
              if (selected != null) _consultationCard(selected),
            ],
          ),
        ),
      ),
    );
  }

  Widget _countBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _medRow(Map<String, dynamic> item, bool over) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            over ? Icons.check_circle : Icons.access_time,
            size: 20,
            color: over ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item['name'] ?? 'Unknown',
              style: TextStyle(
                decoration: over
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Qty: ${item['qty']}',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.teal,
      ),
    );
  }

  Widget _emptyBox(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text, style: TextStyle(color: Colors.grey.shade600)),
    );
  }

  Widget _buildHeader(Map<String, dynamic> hospital, List patients) {
    final Map<String, dynamic>? firstPatient = patients.isNotEmpty
        ? (patients[0] as Map<String, dynamic>)
        : null;
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundImage: NetworkImage(hospital['photo'] ?? ''),
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    firstPatient?['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 14, color: Colors.teal),
                      const SizedBox(width: 6),
                      Text(
                        firstPatient?['user_Id'] ?? '',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          firstPatient?['address']?['Address'] ?? '',
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
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
  }

  Widget _consultationCard(Map<String, dynamic> c) {
    final status = (c['status'] ?? '').toString();
    final createdDateLabel = c['createdAt'] != null
        ? timeAgoSafe(c['createdAt'].toString())
        : '';

    Color statusColor;
    switch (status.toUpperCase()) {
      case 'PENDING':
        statusColor = Colors.blue;
        break;
      case 'ONGOING':
        statusColor = Colors.green;
        break;
      case 'ENDPROCESSING':
        statusColor = Colors.orange;
        break;
      case 'COMPLETED':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.blueGrey;
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.medical_services, size: 30, color: Colors.teal),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c['purpose'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Doctor: ${c['doctor_Id'] ?? ''}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status.toUpperCase() == 'COMPLETED' ? createdDateLabel : status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
