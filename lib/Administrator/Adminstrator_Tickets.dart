import 'package:flutter/material.dart';
import 'package:hospitrax/Services/submit_tickets.dart';
import '../Pages/NotificationsPage.dart';

class AdministratorTickets extends StatefulWidget {
  const AdministratorTickets({super.key});

  @override
  State<AdministratorTickets> createState() => _AdministratorTicketsState();
}

class _AdministratorTicketsState extends State<AdministratorTickets> {
  final SubmitTickets submitTickets = SubmitTickets();

  List<dynamic> tickets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTickets();
  }

  /// 🔄 LOAD DATA
  Future<void> loadTickets() async {
    try {
      final data = await submitTickets.getAll();

      if (!mounted) return;

      setState(() {
        tickets = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  /// 🗑 DELETE WITH CONFIRMATION
  void deleteTicket(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Ticket"),
        content: const Text("Are you sure you want to delete this ticket?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              await submitTickets.deleteTicket(id);

              loadTickets();
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void updateTicket(int id, String status) async {
    final data = await submitTickets.updateTicket(id, status);
    loadTickets();
    Navigator.pop(context);
  }

  /// 📄 OPEN DETAILS
  void openDetails(dynamic ticket) {
    final statusColor = getStatusColor(ticket['status']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,

      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.5,
          maxChildSize: 0.9,

          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),

              child: SingleChildScrollView(
                controller: scrollController,

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 🔘 DRAG HANDLE
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    /// 🔝 HEADER
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Ticket #${ticket['id']}",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        /// STATUS CHIP
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            ticket['status'],
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// 🧾 INFO CARD
                    _infoCard([
                      _infoRow("Hospital ID", ticket['hospital_Id']),
                      _infoRow("Staff ID", ticket['admin_Id']),
                    ]),

                    const SizedBox(height: 16),

                    /// 📝 DESCRIPTION
                    const Text(
                      "Description",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        ticket['description'] ?? '',
                        style: TextStyle(
                          height: 1.4,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// 📅 META INFO
                    _infoCard([
                      _infoRow("Created", ticket['created_at']),
                      _infoRow("Updated", ticket['updated_at']),
                    ]),

                    const SizedBox(height: 20),

                    /// ⚙️ ACTIONS
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              updateTicket(ticket['id'], 'RESOLVED');
                            },
                            icon: const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Resolved",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              updateTicket(ticket['id'], "CLOSED");
                            },
                            icon: const Icon(Icons.cancel, color: Colors.white),
                            label: const Text(
                              "Closed",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        //const SizedBox(width: 10),
                      ],
                    ),
                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              updateTicket(ticket['id'], "IN_PROGRESS");
                            },
                            icon: const Icon(
                              Icons.watch_later,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "On Progress",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 🎨 STATUS COLOR
  Color getStatusColor(String status) {
    switch (status) {
      case "OPEN":
        return Colors.blue;
      case "IN_PROGRESS":
        return Colors.orange;
      case "RESOLVED":
        return Colors.green;
      case "CLOSED":
        return Colors.grey;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFFC59A62),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  const Text(
                    "View Tickets",
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

      /// 🔽 BODY
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tickets.isEmpty
          ? Center(
              child: Text(
                "No Tickets Found !",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 20),
              ),
            )
          : RefreshIndicator(
              onRefresh: loadTickets,
              child: ListView.builder(
                itemCount: tickets.length,
                padding: const EdgeInsets.all(14),
                itemBuilder: (context, index) {
                  final ticket = tickets[index];
                  final statusColor = getStatusColor(ticket['status']);

                  return GestureDetector(
                    onTap: () => openDetails(ticket),

                    child: Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),

                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                        ),

                        child: Row(
                          children: [
                            /// 🔸 LEFT STRIP (MODERN)
                            Container(
                              width: 6,
                              height: 120,
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  bottomLeft: Radius.circular(20),
                                ),
                              ),
                            ),

                            /// 🔳 CONTENT
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16),

                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    /// 🔝 HEADER
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "Ticket #${ticket['id']}",
                                            style: const TextStyle(
                                              fontSize: 16.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),

                                        /// STATUS CHIP (UPGRADED)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(
                                              0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                          child: Text(
                                            ticket['status'],
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 10),

                                    /// 📝 DESCRIPTION
                                    Text(
                                      ticket['description'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.4,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    /// 📅 + ACTIONS ROW
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.schedule_rounded,
                                          size: 15,
                                          color: Colors.grey.shade500,
                                        ),
                                        const SizedBox(width: 6),

                                        Expanded(
                                          child: Text(
                                            ticket['created_at'] ?? '',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),

                                        _actionButton(
                                          icon: Icons.delete_rounded,
                                          color: Colors.red,
                                          onTap: () =>
                                              deleteTicket(ticket['id']),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(
              value?.toString() ?? '',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
