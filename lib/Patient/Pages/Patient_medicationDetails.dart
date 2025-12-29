import 'package:flutter/material.dart';

const primaryColor = Color(0xFFBF955E);
const softBackground = Color(0xFFF7FAFC);
const cardBackground = Colors.white;

class MedicationDetailPage extends StatelessWidget {
  final String title;
  final Map<String, dynamic> data;

  const MedicationDetailPage({
    super.key,
    required this.title,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: _buildAppBar(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          _buildConsultationInfo(),
          const SizedBox(height: 20),
          if (_hasList("MedicinePatients"))
            _sectionCard(
              title: "Medicines",
              icon: Icons.medication_liquid,
              children: data["MedicinePatients"]
                  .map<Widget>((m) => _medicineTile(m))
                  .toList(),
            ),
          if (_hasList("InjectionPatients"))
            _sectionCard(
              title: "Injections",
              icon: Icons.vaccines,
              children: data["InjectionPatients"]
                  .map<Widget>((m) => _injectionTile(m))
                  .toList(),
            ),
          if (_hasList("TonicPatients"))
            _sectionCard(
              title: "Tonics",
              icon: Icons.science,
              children: data["TonicPatients"]
                  .map<Widget>((m) => _tonicTile(m))
                  .toList(),
            ),
        ],
      ),
    );
  }

  bool _hasList(String key) =>
      data[key] != null && (data[key] as List).isNotEmpty;

  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, Colors.amber.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.notifications_active,
                  color: Colors.white,
                ),
                onPressed: () {
                  // Push to notifications page
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsultationInfo() {
    return _sectionCard(
      title: "Consultation Details",
      icon: Icons.assignment_turned_in,
      children: [
        // _infoRow("Purpose", data['purpose']),
        _infoRow("Patient ID", data["patient_Id"]),
        const SizedBox(height: 6),
        _statusChip(data["status"]),
        const SizedBox(height: 6),
        // _infoRow("Created At", data["createdAt"]),
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: 16,
            spreadRadius: 2,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, Colors.amber.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              children: [
                Icon(icon, size: 28, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
            ),
          ),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    IconData icon;
    Color c = Colors.grey;
    switch (status.toLowerCase()) {
      case "pending":
        c = Colors.orange;
        icon = Icons.access_time;
        break;
      case "completed":
        c = Colors.green;
        icon = Icons.check_circle;
        break;
      case "cancelled":
        c = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        icon = Icons.help_outline;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: c, size: 18),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: c,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Medicine card with table display
  Widget _medicineTile(dynamic m) {
    var med = m["Medician"] ?? {};
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medication, color: primaryColor, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  med["medicianName"] ?? "Unknown Medicine",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _eatTag(m["afterEat"]),
            ],
          ),
          const SizedBox(height: 10),
          Table(
            columnWidths: const {
              0: FixedColumnWidth(60),
              1: FixedColumnWidth(70),
              2: FixedColumnWidth(70),
              3: FixedColumnWidth(70),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.blue.shade100),
                children: [
                  _tableHeader("Days"),
                  _tableHeader("MN"),
                  _tableHeader("AF"),
                  _tableHeader("NT"),
                ],
              ),
              TableRow(
                children: [
                  _tableCell(m["days"]?.toString() ?? "-"),
                  _tableCell(
                    m["morning"] == true ? m["quantity"].toString() : "-",
                  ),
                  _tableCell(
                    m["afternoon"] == true ? m["quantity"].toString() : "-",
                  ),
                  _tableCell(
                    m["night"] == true ? m["quantity"].toString() : "-",
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tonicTile(dynamic m) {
    var t = m["Tonic"] ?? {};
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science, color: primaryColor, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t["tonicName"] ?? "Unknown Tonic",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _eatTag(m["afterEat"]),
            ],
          ),
          const SizedBox(height: 10),
          Table(
            columnWidths: const {
              0: FixedColumnWidth(65),
              1: FixedColumnWidth(70),
              2: FixedColumnWidth(70),
              3: FixedColumnWidth(70),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.green.shade100),
                children: [
                  _tableHeader("Qty"),
                  _tableHeader("MN"),
                  _tableHeader("AF"),
                  _tableHeader("NT"),
                ],
              ),
              TableRow(
                children: [
                  _tableCell("${m["quantity"]}ml".toString()),
                  _tableCell(
                    m["morning"] == true
                        ? "${m["Doase"].toString().split('.').first}ml"
                        : "-",
                  ),
                  _tableCell(
                    m["afternoon"] == true
                        ? "${m["Doase"].toString().split('.').first}ml"
                        : "-",
                  ),
                  _tableCell(
                    m["night"] == true
                        ? "${m["Doase"].toString().split('.').first}ml"
                        : "-",
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _injectionTile(dynamic m) {
    var inj = m["Injection"] ?? {};
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.vaccines, color: primaryColor, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  inj["injectionName"] ?? "Unknown Injection",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Table(
            columnWidths: const {
              0: FixedColumnWidth(60),
              1: FixedColumnWidth(70),
              2: FixedColumnWidth(70),
              3: FixedColumnWidth(70),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.red.shade100),
                children: [
                  _tableHeader("Dose"),
                  _tableHeader("MN"),
                  _tableHeader("AF"),
                  _tableHeader("NT"),
                ],
              ),
              TableRow(
                children: [
                  _tableCell(m["quantity"]?.toString() ?? "-"),
                  _tableCell(
                    m["morning"] == true ? m["quantity"].toString() : "-",
                  ),
                  _tableCell(
                    m["afternoon"] == true ? m["quantity"].toString() : "-",
                  ),
                  _tableCell(
                    m["night"] == true ? m["quantity"].toString() : "-",
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.black87,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _tableCell(String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _eatTag(bool afterEat) {
    return Chip(
      label: Text(
        afterEat ? "After Eat" : "Before Eat",
        style: TextStyle(
          color: afterEat ? Colors.orange.shade800 : Colors.green.shade800,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      backgroundColor: afterEat
          ? Colors.orange.shade100
          : Colors.green.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
