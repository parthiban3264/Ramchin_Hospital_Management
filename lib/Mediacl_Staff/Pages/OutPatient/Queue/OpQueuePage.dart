import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../../../../Services/Doctor/doctor_service.dart';
import '../../../../Services/consultation_service.dart';
import '../../../../Pages/NotificationsPage.dart';
import '../../../../Services/socket_service.dart';
import '../Page/SymptomsPage.dart';

class OutpatientQueuePage extends StatefulWidget {
  const OutpatientQueuePage({super.key});

  @override
  _OutpatientQueuePageState createState() => _OutpatientQueuePageState();
}

class _OutpatientQueuePageState extends State<OutpatientQueuePage>
    with TickerProviderStateMixin {
  final Color primaryColor = const Color(0xFFBF955E);
  final Color darkText = const Color(0xFF1F1F1F);

  late Future<List<Map<String, dynamic>>> futureDoctors;
  Map<String, List<Map<String, dynamic>>> doctorQueues = {};
  List<Map<String, dynamic>> allConsultations = [];
  final socketService = SocketService();

  String? selectedDoctorId; // null = all patients
  bool isInitialLoading = true;
  int selectedTabIndex = 0; // 0: Pending, 1: Consulting
  String? movingPatientId;
  late TabController _consultingTabController;

  final List<Color> doctorColors = const [
    Color(0xFF1F8795),
    Color(0xFFE53935),
    Color(0xFF00796B),
    Color(0xFF1E88E5),
    Color(0xFF5D6D7E),
    Color(0xFF8E44AD),
  ];

  late AnimationController _glowController;
  late Animation<Color?> _glowAnimation;
  String? _dateTime;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _consultingTabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (mounted) setState(() {});
      });

    futureDoctors = DoctorService().getDoctors();
    _fetchAllAndQueues(firstLoad: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.red.withValues(alpha: 0.6),
    ).animate(_glowController);

    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchAllAndQueues();
    });
    _updateTime();
  }

  @override
  void dispose() {
    _consultingTabController.dispose();

    _glowController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    setState(() {
      _dateTime = DateFormat('yyyy-MM-dd hh:mm a').format(DateTime.now());
    });
  }

  bool _doctorHasBehind(String doctorId) {
    final queue = doctorQueues[doctorId];
    if (queue == null) return false;
    return queue.any(
      (item) => item['queueStatus']?.toString().toLowerCase() == 'behind',
    );
  }

  bool _doctorHasPending(String doctorId) {
    final queue = doctorQueues[doctorId];
    if (queue == null) return false;
    return queue.any(
      (item) => item['queueStatus']?.toString().toLowerCase() == 'pending',
    );
  }

  bool _doctorHasOngoing(String doctorId) {
    final queue = doctorQueues[doctorId];
    if (queue == null) return false;
    return queue.any(
      (item) => item['queueStatus']?.toString().toLowerCase() == 'ongoing',
    );
  }

  bool _hasTodayConsulting(List<Map<String, dynamic>> consultations) {
    final now = DateTime.now();

    return consultations.any((c) {
      final queueStatus = (c['queueStatus'] ?? '').toString().toLowerCase();
      if (queueStatus != 'drqueue' && queueStatus != 'ongoing') return false;

      final createdAt = DateTime.tryParse(c['createdAt'] ?? '');
      if (createdAt == null) return false;

      return createdAt.year == now.year &&
          createdAt.month == now.month &&
          createdAt.day == now.day;
    });
  }

  DateTime? _parseCreatedAt(String? dateStr) {
    if (dateStr == null) return null;
    try {
      return DateFormat('yyyy-MM-dd hh:mm a').parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  bool _hasPreviousConsulting(List<Map<String, dynamic>> consultations) {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    return consultations.any((c) {
      final queueStatus = (c['queueStatus'] ?? '').toString().toLowerCase();
      if (queueStatus != 'drqueue' && queueStatus != 'ongoing') return false;

      final createdAt = _parseCreatedAt(c['createdAt']);
      if (createdAt == null) return false;

      return createdAt.isBefore(startOfToday);
    });
  }

  bool _hasPreviousPending(List<Map<String, dynamic>> consultations) {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    return consultations.any((c) {
      final status = (c['status'] ?? '').toString().toLowerCase();
      final queueStatus = (c['queueStatus'] ?? '').toString().toLowerCase();
      final scanningTesting = c['scanningTesting'] ?? false;

      if (!((status == 'pending' || status == 'endprocessing') &&
          queueStatus == 'pending' &&
          scanningTesting == false)) {
        return false;
      }

      final createdAt = _parseCreatedAt(c['createdAt']);
      if (createdAt == null) return false;

      return createdAt.isBefore(startOfToday);
    });
  }

  List<Map<String, dynamic>> _filterConsultingByDate(
    List<Map<String, dynamic>> consultations,
    int tabIndex,
  ) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    return consultations.where((c) {
      final queueStatus = (c['queueStatus'] ?? '').toString().toLowerCase();
      if (queueStatus != 'drqueue' && queueStatus != 'ongoing') return false;

      final createdAt = _parseCreatedAt(c['createdAt']);

      if (createdAt == null) return false;

      final isToday =
          createdAt.isAfter(startOfToday) ||
          createdAt.isAtSameMomentAs(startOfToday);

      return tabIndex == 0 ? isToday : !isToday;
    }).toList();
  }

  List<Map<String, dynamic>> _filterPendingByDate(
    List<Map<String, dynamic>> consultations,
    int tabIndex,
  ) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    return consultations.where((c) {
      final status = (c['status'] ?? '').toString().toLowerCase();
      final queueStatus = (c['queueStatus'] ?? '').toString().toLowerCase();
      final scanningTesting = c['scanningTesting'] ?? false;

      if (!((status == 'pending' || status == 'endprocessing') &&
          queueStatus == 'pending' &&
          scanningTesting == false)) {
        return false;
      }

      final createdAt = _parseCreatedAt(c['createdAt']);
      if (createdAt == null) return false;

      final isToday =
          createdAt.isAfter(startOfToday) ||
          createdAt.isAtSameMomentAs(startOfToday);

      return tabIndex == 0 ? isToday : !isToday;
    }).toList();
  }

  void _openDialog(
    BuildContext context,
    String consultationId,
    String queueStatus,
    String status,
  ) {
    final TextEditingController controller = TextEditingController();
    const primaryColor = Color(0xFFBF955E); // Your theme color

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon + Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.assignment_ind_rounded,
                        color: primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      "Cancellation \n Reason",
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // subtitle
                Text(
                  "Please tell us why you need to cancel. (optional)",
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),

                const SizedBox(height: 20),

                // Input box
                TextField(
                  controller: controller,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText:
                        "Enter reason (ex: patient unavailable, reschedule)...",
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.all(16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: primaryColor.withValues(alpha: 0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: primaryColor, width: 1.6),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor: primaryColor,
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor: Colors.white,
                          elevation: 2,
                        ),
                        onPressed: () async {
                          final int parsedId = int.parse(consultationId);
                          final reason = controller.text.trim();
                          queueStatus == 'pending'
                              ? await ConsultationService()
                                    .updateConsultation(parsedId, {
                                      'status': 'CANCELLED',
                                      'queueStatus': 'CANCELLED',
                                      'cancelReason': reason,
                                      'updatedAt': _dateTime,
                                    })
                              : await ConsultationService()
                                    .updateConsultation(parsedId, {
                                      'queueStatus': 'PENDING',
                                      'cancelReason': reason,
                                      'updatedAt': _dateTime,
                                    });
                          // 🔥 2. Update UI instantly (no waiting 10 sec timer)
                          setState(() {
                            // Find and update local list
                            for (var c in allConsultations) {
                              if (c['id'] == parsedId) {
                                c['status'] = 'CANCELLED';
                                c['queueStatus'] = 'cancelled';
                                c['cancelReason'] = reason;
                              }
                            }
                          });
                          if (context.mounted) Navigator.pop(context);
                        },

                        child: const Text(
                          "Submit",
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _fetchAllAndQueues({bool firstLoad = false}) async {
    if (firstLoad) {
      setState(() => isInitialLoading = true);
    }
    try {
      final consultations = await ConsultationService().getAllConsultation();
      final doctors = await futureDoctors;

      final mappedConsults = consultations
          .map<Map<String, dynamic>>((c) => c.cast<String, dynamic>())
          .toList();

      final newQueues = <String, List<Map<String, dynamic>>>{};
      for (var doc in doctors) {
        final doctorId = doc['id'].toString();
        newQueues[doctorId] = mappedConsults
            .where((c) => c['doctor_Id'].toString() == doctorId)
            .toList();
      }

      setState(() {
        isInitialLoading = false;
        allConsultations = mappedConsults;
        doctorQueues = newQueues;
      });
    } catch (e) {
      if (firstLoad) setState(() => isInitialLoading = false);
      //print('Error fetching consultations: $e');
    }
  }

  List<Map<String, dynamic>> _filterByTab(
    List<Map<String, dynamic>> consultations,
  ) {
    if (selectedTabIndex == 0) {
      // Pending tab: status pending or endprocessing AND queueStatus pending
      return consultations.where((c) {
        final status = (c['status'] ?? '').toString().toLowerCase();
        final queueStatus = (c['queueStatus'] ?? '').toString().toLowerCase();
        final scanningTesting = c['scanningTesting'] ?? false;
        return ((status == 'pending' || status == 'endprocessing') &&
                scanningTesting == false) &&
            queueStatus == 'pending';
      }).toList();
    } else if (selectedTabIndex == 1) {
      // Consulting tab: queueStatus drqueue or ongoing
      return consultations.where((c) {
        final queueStatus = (c['queueStatus'] ?? '').toString().toLowerCase();
        return queueStatus == 'drqueue' || queueStatus == 'ongoing';
      }).toList();
    } else {
      return consultations.where((c) {
        final status = (c['status'] ?? '').toString().toLowerCase();

        return status == 'cancelled';
      }).toList();
    }
  }

  // Color _getCardColor(Map<String, dynamic> consultation) {
  //   final status = (consultation['status'] ?? '').toString().toLowerCase();
  //   final queueStatus = (consultation['queueStatus'] ?? '')
  //       .toString()
  //       .toLowerCase();
  //
  //   if (status == 'endprocessing' && queueStatus == 'pending') {
  //     return Colors.amber.shade100;
  //   }
  //   if (queueStatus == 'drqueue' || queueStatus == 'ongoing') {
  //     return Colors.blue.shade100;
  //   }
  //   if (status == 'pending' && queueStatus == 'pending') {
  //     return Colors.grey.shade200;
  //   }
  //
  //   return Colors.white;
  // }

  Widget _doctorCard({
    required String label,
    String? subtitle,
    required bool isSelected,
    required Color color,
    IconData? icon,
    required VoidCallback onTap,
    required bool hasBehind,
    required bool hasPending,
    required bool hasOngoing,
  }) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final borderColor = hasOngoing
            ? (_glowAnimation.value ?? Colors.red.withValues(alpha: 0.5))
            : (isSelected ? color : Colors.grey.shade300);

        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 160,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isSelected
                    ? [color.withValues(alpha: 0.85), color]
                    : [Colors.white, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: borderColor,
                width: isSelected || hasOngoing ? 3 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isSelected ? 0.15 : 0.08,
                  ),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),

            // 👇 Center everything vertically and horizontally
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (icon != null)
                    Icon(
                      icon,
                      color: isSelected ? Colors.white : color,
                      size: 32,
                    ),
                  if (icon != null) const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : darkText,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.9)
                              : Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _consultationCard(
    Map<String, dynamic> item,
    Color accentColor,
    List<Map<String, dynamic>> doctors,
  ) {
    print('item: $item');
    final patient = item['Patient'] ?? {};

    final phone = patient['phone']?['mobile'] ?? '-';
    final drId = item['doctor_Id'] ?? '';
    final selectedDoctor = doctors.firstWhere(
      (doc) => doc['id'].toString() == drId.toString(),
      orElse: () => {},
    );

    final drName = selectedDoctor['name'];
    print(selectedDoctor);
    final specialist = selectedDoctor['department'];

    final address = patient['address']?['Address'] ?? '-';
    final queueStatus = item['queueStatus']?.toString().toLowerCase() ?? '';
    bool isOngoing = queueStatus == 'ongoing' || queueStatus == 'drqueue';
    bool isOngoings = queueStatus == 'ongoing';
    bool isdrqueue = queueStatus == 'drqueue';
    final status = item['status']?.toString().toLowerCase().trim() ?? '';
    final emergency = item['emergency'] ?? false;

    final bool isCancelled = status == 'cancelled';
    final bool isPending = status == 'pending';
    final bool isEndProcessing = status == 'endprocessing';

    final Color pendingBgColor = Colors.orange.shade50;
    final Color pendingTextColor = Colors.orange.shade700;

    final Color endProcessingBgColor = Colors.green.shade50;
    final Color endProcessingTextColor = Colors.green.shade700;

    final cancelReason = item['cancelReason'] ?? 'No reason provided';
    final tokenNo = (item['tokenNo'] == null || item['tokenNo'] == 0)
        ? '-'
        : item['tokenNo'].toString();

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final glowColor = isOngoings
            ? _glowAnimation.value
            : accentColor.withValues(alpha: 0.4);
        final borderWidth = isOngoings ? 4.0 : 1.0;
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: isPending
                ? pendingBgColor
                : isEndProcessing
                ? endProcessingBgColor
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: glowColor ?? accentColor.withValues(alpha: 0.4),
              width: borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (emergency == true) ...[
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "EMERGENCY",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                Row(
                  //crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Token No: ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      tokenNo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        patient['name'] ?? 'Unknown',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: darkText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      "ID: ${patient['id'] ?? 'N/A'}",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                if (isCancelled) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3F3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.redAccent.withValues(alpha: 0.15),
                          ),
                          child: const Icon(
                            Icons.cancel_rounded,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Reason",
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                  color: Colors.redAccent,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                cancelReason,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.45,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                _infoRow(Icons.phone, "Cell No", phone),
                _infoRow(Icons.home, "Address", address),
                const SizedBox(height: 4),
                if (!isCancelled)
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 15, color: accentColor),
                      const SizedBox(width: 6),
                      Text(
                        "Created: ${formatDate(item['createdAt'])}",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (isPending) ...[
                        const Spacer(),
                        // ✅ Make edit icon clickable
                        GestureDetector(
                          onTap: () async {
                            final sugarData = item['sugerTest'] ?? false;
                            final sugarValue = item['sugar']?.toString() ?? '';
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SymptomsPage(
                                  patient: item['Patient'] ?? {},
                                  consultationId: item['id'],
                                  sugarData: sugarData,
                                  sugar: sugarValue,
                                  consultationData: item,
                                  mode: 2,
                                  history: false,
                                  index: 0,
                                ),
                              ),
                            );

                            // Refresh list if needed
                            // if (result == true) {
                            //   setState(() {
                            //     futurePatients = PaymentService().getAllPaid();
                            //   });
                            // }
                          },
                          child: Icon(Icons.edit, size: 18, color: accentColor),
                        ),
                      ],
                    ],
                  ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          drName ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          specialist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),

                    Spacer(),
                    if (queueStatus == 'pending' || queueStatus == 'drqueue')
                      IconButton(
                        iconSize: 40,
                        onPressed: () => _openDialog(
                          context,
                          item['id'].toString(),
                          item['queueStatus'].toString().toLowerCase(),
                          item['status'].toString().toLowerCase(),
                        ),
                        icon: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFFE5E5),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.cancel,
                            color: Colors.red,
                            size: 26,
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),

                    const SizedBox(width: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: isOngoing
                          ? ElevatedButton(
                              onPressed: null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade400,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(90, 36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: isdrqueue
                                  ? const Text('Consulting')
                                  : Text('Consulting . . .'),
                            )
                          : queueStatus == 'cancelled'
                          ? // Cancelled Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD2D2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                "Cancelled",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8E0000),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: () async {
                                setState(() {
                                  movingPatientId = patient['id']?.toString();
                                });

                                await ConsultationService.updateQueueStatus(
                                  item['id'],
                                  'DRQUEUE',
                                );

                                setState(() {
                                  movingPatientId = null;
                                });

                                _fetchAllAndQueues();
                              },
                              icon: movingPatientId == patient['id'].toString()
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.send),
                              label: const Text('Send'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(90, 36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.black54),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              "$label: $value",
              style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateFormat("yyyy-MM-dd hh:mm a").parse(dateStr);
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    print('consultations.l $allConsultations');
    final allPatientsColor = primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
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
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "Outpatient Queue",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.group_rounded, color: Colors.white),
                    tooltip: "Show All Patients",
                    onPressed: () {
                      setState(() {
                        selectedDoctorId = null;
                      });
                    },
                  ),
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: futureDoctors,
        builder: (context, snapshot) {
          if (isInitialLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Lottie.asset(
                'assets/Lottie/error404.json',
                width: 300,
                height: 300,
                fit: BoxFit.contain,
                repeat: true,
              ),
            );
          }
          final doctors = snapshot.data ?? [];

          if (allConsultations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/Lottie/NoData.json',
                    width: 300,
                    height: 300,
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                  const SizedBox(height: 16),
                  selectedTabIndex != 2
                      ? Text(
                          "No patients in queue",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        )
                      : Text(
                          "No Cancel patients in queue",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                ],
              ),
            );
          }

          Color accentColor;
          if (selectedDoctorId == null) {
            accentColor = allPatientsColor;
          } else {
            final docIndex = doctors.indexWhere(
              (d) => d['id'].toString() == selectedDoctorId,
            );
            accentColor = docIndex >= 0
                ? doctorColors[docIndex % doctorColors.length]
                : primaryColor;
          }

          final consultationsForDoctor = selectedDoctorId == null
              ? allConsultations
              : (doctorQueues[selectedDoctorId] ?? []);

          //final filteredQueue = _filterByTab(consultationsForDoctor);

          // final bool isConsultingTab = selectedTabIndex == 1;
          //
          // final bool hasPreviousConsulting = _hasPreviousConsulting(
          //   consultationsForDoctor,
          // );
          final bool isPendingTab = selectedTabIndex == 0;
          final bool isConsultingTab = selectedTabIndex == 1;

          final bool hasPreviousPending = _hasPreviousPending(
            consultationsForDoctor,
          );

          final bool hasPreviousConsulting = _hasPreviousConsulting(
            consultationsForDoctor,
          );

          final bool showDateTabs =
              (isPendingTab && hasPreviousPending) ||
              (isConsultingTab && hasPreviousConsulting);

          final bool showConsultingTabs =
              isConsultingTab && hasPreviousConsulting;

          // final List<Map<String, dynamic>> filteredQueue = showConsultingTabs
          //     ? _filterConsultingByDate(
          //         consultationsForDoctor,
          //         _consultingTabController.index,
          //       )
          //     : _filterByTab(consultationsForDoctor);

          // final List<Map<String, dynamic>> filteredQueue = selectedTabIndex == 1
          //     ? (showConsultingTabs
          //           ? _filterConsultingByDate(
          //               consultationsForDoctor,
          //               _consultingTabController.index,
          //             )
          //           : _filterConsultingByDate(
          //               consultationsForDoctor,
          //               0, // today only
          //             ))
          //     : _filterByTab(consultationsForDoctor);
          final List<Map<String, dynamic>> filteredQueue = selectedTabIndex == 0
              ? (showDateTabs
                    ? _filterPendingByDate(
                        consultationsForDoctor,
                        _consultingTabController.index,
                      )
                    : _filterPendingByDate(
                        consultationsForDoctor,
                        0, // today only
                      ))
              : selectedTabIndex == 1
              ? (showDateTabs
                    ? _filterConsultingByDate(
                        consultationsForDoctor,
                        _consultingTabController.index,
                      )
                    : _filterConsultingByDate(consultationsForDoctor, 0))
              : _filterByTab(consultationsForDoctor);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: doctors.length,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemBuilder: (context, index) {
                    final doc = doctors[index];
                    print('doc $doc');
                    final doctorId = doc['id'].toString();
                    final color = doctorColors[index % doctorColors.length];
                    final isSelected = selectedDoctorId == doctorId;
                    final hasBehind = _doctorHasOngoing(doctorId)
                        ? false
                        : _doctorHasBehind(doctorId);
                    final status = doc['status'];
                    print('docstatus $status');
                    final hasPending = _doctorHasPending(doctorId);
                    final hasOngoing = _doctorHasOngoing(doctorId);

                    return _doctorCard(
                      label: doc['name'] ?? 'Unknown',
                      subtitle: doc['department'] ?? 'General',
                      isSelected: isSelected,
                      color: color,
                      onTap: () {
                        setState(() => selectedDoctorId = doctorId);
                        _consultingTabController.index = 0; // 🔥 reset
                      },
                      hasBehind: hasBehind,
                      hasPending: hasPending,
                      hasOngoing: hasOngoing,
                    );
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.only(
                  top: 0,
                  bottom: 0,
                  left: 20,
                  right: 20,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accentColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_alt_rounded, color: accentColor),
                    const SizedBox(width: 8),
                    Text(
                      selectedDoctorId == null
                          ? "All Waiting Patients"
                          : "Waiting Patients",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "( ${filteredQueue.length} )",
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              if (showDateTabs)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 1,
                  ),
                  child: TabBar(
                    controller: _consultingTabController,
                    labelColor: accentColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: accentColor,
                    tabs: const [
                      Tab(text: "Current"),
                      Tab(text: "Previous"),
                    ],
                  ),
                ),
              SizedBox(height: 10),
              Expanded(
                child: filteredQueue.isEmpty
                    ? Center(
                        child: selectedTabIndex != 2
                            ? const Text(
                                "No patients in queue",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              )
                            : const Text(
                                "No Cancel patients in queue",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredQueue.length,
                        itemBuilder: (context, index) {
                          return _consultationCard(
                            filteredQueue[index],
                            accentColor,
                            doctors,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black26, spreadRadius: 0, blurRadius: 10),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            backgroundColor: primaryColor,
            currentIndex: selectedTabIndex,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white38,
            onTap: (index) {
              setState(() {
                selectedTabIndex = index;
                // 🔥 reset consulting tabs when entering Consulting
                if (index == 1) {
                  _consultingTabController.index = 0;
                }
              });
            },
            selectedLabelStyle: const TextStyle(fontSize: 15),
            unselectedLabelStyle: const TextStyle(fontSize: 15),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.schedule),
                label: 'Pending',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.run_circle_outlined),
                label: 'Consulting',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.cancel_outlined),
                label: 'Cancel',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
