import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Services/admin_service.dart';

import '../../../Services/fees_service.dart';

class AssignFeesPage extends StatefulWidget {
  const AssignFeesPage({super.key});

  @override
  State<AssignFeesPage> createState() => _AssignFeesPageState();
}

class _AssignFeesPageState extends State<AssignFeesPage> {
  final FeesService service = FeesService();

  final AdminService doctorService = AdminService();

  List<dynamic> feesList = [];
  List<dynamic> doctorList = [];

  bool isLoading = true;

  // Button loading states
  bool isFeeButtonLoading = false;
  bool isDeleteButtonLoading = false;
  bool isDoctorButtonLoading = false;

  final List<String> feeTypes = [
    "REGISTRATION FEE",
    'EMERGENCY FEE',
    'SUGAR FEE',
    'INPATIENT ADVANCE FEE',
    'INPATIENT DOCTOR FEE',
    'INPATIENT NURSE FEE',
  ];

  @override
  void initState() {
    super.initState();
    loadFees();
  }

  void loadFees() async {
    setState(() => isLoading = true);

    final data = await service.getFeesByHospital();

    final doctors = await doctorService.getMedicalStaff();

    setState(() {
      feesList = data;

      // doctorList = doctors
      //     .where(
      //       (d) =>
      //           d["role"].toString().toLowerCase() == "doctor" ||
      //           d["role"].toString().toLowerCase() == "admin" &&
      //               d['accessDoctorRole'] == true,
      //     )
      //     .toList();
      doctorList =
          doctors
              .where(
                (d) =>
                    d["role"].toString().toLowerCase() == "doctor" ||
                    // d["role"].toString().toLowerCase() == "nurse" ||
                    (d["role"].toString().toLowerCase() == "admin" &&
                        d["accessDoctorRole"] == true),
              )
              .toList()
            ..sort((a, b) {
              final roleA = a["role"].toString().toLowerCase();
              final roleB = b["role"].toString().toLowerCase();

              if (roleA == "admin" && roleB == "doctor") return -1;
              if (roleA == "doctor" && roleB == "admin") return 1;
              return 0;
            });
      // final rolePriority = {'admin': 0, 'doctor': 1};
      //
      // doctorList.sort((a, b) {
      //   final roleA = a["role"].toString().toLowerCase();
      //   final roleB = b["role"].toString().toLowerCase();
      //
      //   return (rolePriority[roleA] ?? 99).compareTo(rolePriority[roleB] ?? 99);
      // });

      isLoading = false;
    });
  }

  List<String> getAvailableFeeTypes({Map<String, dynamic>? editingFee}) {
    final existingTypes = feesList.map((f) => f["type"].toString()).toList();

    // If editing, allow current type to remain selectable
    if (editingFee != null) {
      existingTypes.remove(editingFee["type"]);
    }

    return feeTypes.where((type) => !existingTypes.contains(type)).toList();
  }

  // ---------------------- Create / Edit Fee Modal ---------------------- //
  void openFeeModal({Map<String, dynamic>? fee}) {
    //String selectedType = fee != null ? fee["type"] : feeTypes.first;

    final TextEditingController amountCtrl = TextEditingController(
      text: fee != null ? fee["amount"].toString() : "",
    );

    final availableFeeTypes = getAvailableFeeTypes(editingFee: fee);

    String selectedType = fee != null ? fee["type"] : availableFeeTypes.first;

    isFeeButtonLoading = false;
    isDeleteButtonLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),

      builder: (context) => StatefulBuilder(
        builder: (context, modalSetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 18,
              right: 18,
              top: 22,
              bottom: MediaQuery.of(context).viewInsets.bottom + 22,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fee == null ? "Create Fee" : "Update Fee",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),

                // DropdownButtonFormField<String>(
                //   value: selectedType,
                //   items: feeTypes
                //       .map(
                //         (type) =>
                //             DropdownMenuItem(value: type, child: Text(type)),
                //       )
                //       .toList(),
                //   onChanged: (value) {
                //     modalSetState(() => selectedType = value!);
                //   },
                //   decoration: InputDecoration(
                //     labelText: "Fee Type",
                //     border: OutlineInputBorder(
                //       borderRadius: BorderRadius.circular(14),
                //     ),
                //   ),
                // ),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: availableFeeTypes
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
                  onChanged: (value) {
                    modalSetState(() => selectedType = value!);
                  },
                  decoration: InputDecoration(
                    labelText: "Fee Type",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Amount",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                // TextField(
                //   controller: inPatientAmountCtrl,
                //   keyboardType: TextInputType.number,
                //   decoration: InputDecoration(
                //     labelText: "In Patient Amount",
                //     border: OutlineInputBorder(
                //       borderRadius: BorderRadius.circular(14),
                //     ),
                //   ),
                // ),
                const SizedBox(height: 18),

                Row(
                  children: [
                    if (fee != null)
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: isDeleteButtonLoading
                              ? null
                              : () async {
                                  modalSetState(
                                    () => isDeleteButtonLoading = true,
                                  );
                                  await service.deleteFee(fee["id"]);
                                  Navigator.pop(context);
                                  loadFees();
                                },
                          child: isDeleteButtonLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Delete",
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ),

                    if (fee != null) const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBF955E),
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: isFeeButtonLoading
                            ? null
                            : () async {
                                modalSetState(() => isFeeButtonLoading = true);
                                final prefs =
                                    await SharedPreferences.getInstance();
                                final hospitalId = prefs.getString(
                                  'hospitalId',
                                );

                                // final hospitalId = await storage.read(
                                //   key: 'hospitalId',
                                // );

                                final payload = {
                                  "hospital_Id": hospitalId,
                                  "type": selectedType,
                                  "amount":
                                      double.tryParse(amountCtrl.text) ?? 0,
                                };

                                if (fee == null) {
                                  await service.createFee(payload);
                                } else {
                                  await service.updateFee(fee["id"], payload);
                                }

                                Navigator.pop(context);
                                loadFees();
                              },
                        child: isFeeButtonLoading
                            ? const SizedBox(
                                height: 25,
                                width: 30,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                fee == null ? "Create" : "Update",
                                style: const TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------- Doctor Fee Modal ---------------------- //
  void openDoctorFeeModal(Map<String, dynamic> doctor) {
    final TextEditingController amountCtrl = TextEditingController(
      text: doctor["doctorAmount"]?.toString() ?? "",
    );
    final TextEditingController inPatientAmountCtrl = TextEditingController(
      text: doctor["inPatientAmount"]?.toString() ?? "",
    );

    isDoctorButtonLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, modalSetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 18,
              right: 18,
              top: 22,
              bottom: MediaQuery.of(context).viewInsets.bottom + 22,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Update Consultation Fee",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // TextField(
                //   enabled: false,
                //   decoration: InputDecoration(
                //     labelText: "Doctor Fee",
                //     border: OutlineInputBorder(
                //       borderRadius: BorderRadius.circular(14),
                //     ),
                //   ),
                // ),
                //const SizedBox(height: 14),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "OUT PATIENT AMOUNT",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                TextField(
                  controller: inPatientAmountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "IN PATIENT AMOUNT",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBF955E),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 40,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: isDoctorButtonLoading
                      ? null
                      : () async {
                          modalSetState(() => isDoctorButtonLoading = true);

                          await doctorService.updateAdminAmount(doctor["id"], {
                            "amount": double.tryParse(amountCtrl.text) ?? 0,
                            "inPatientAmount":
                                double.tryParse(inPatientAmountCtrl.text) ?? 0,
                          });

                          Navigator.pop(context);
                          loadFees();
                        },
                  child: isDoctorButtonLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Update",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------------- //
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),

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
                color: Colors.black.withOpacity(0.1),
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
                    "Assign Fees",
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

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFBF955E)),
            )
          : feesList.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Please assign fees to your hospital first.\nTap the + button below to create a fee.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(14),
              children: [
                // ------------------ Existing Fees ------------------ //
                ...feesList.map(
                  (fee) => Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(20),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBF955E).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.currency_rupee,
                          color: Color(0xFFBF955E),
                          size: 28,
                        ),
                      ),
                      title: Text(
                        fee["type"],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          "Amount: ₹${fee["amount"]}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      trailing: const Icon(
                        Icons.edit,
                        color: Color(0xFFBF955E),
                        size: 28,
                      ),
                      onTap: () => openFeeModal(fee: fee),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                if (doctorList.isNotEmpty)
                  const Text(
                    "Doctor Fees",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                const SizedBox(height: 10),

                // ------------------ Doctor Fees ------------------ //
                ...doctorList.map(
                  (doctor) => Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),

                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFBF955E).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFFBF955E),
                          size: 26,
                        ),
                      ),

                      title: Text(
                        doctor["name"] ?? '',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Role + Specialist
                            Text(
                              '${doctor["role"]} • ${doctor["specialist"]?.isEmpty ?? true ? 'General' : doctor["specialist"]}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Fees row (aligned)
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'OP: ₹${doctor["doctorAmount"] ?? 0}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'IP: ₹${doctor["inPatientAmount"] ?? 0}',
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      trailing: const Icon(
                        Icons.edit_outlined,
                        color: Color(0xFFBF955E),
                        size: 22,
                      ),

                      onTap: () => openDoctorFeeModal(doctor),
                    ),
                  ),
                ),
                const SizedBox(height: 70),
              ],
            ),

      floatingActionButton: feesList.length < 6
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFBF955E),
              child: const Icon(Icons.add, size: 30, color: Colors.white),
              onPressed: () => openFeeModal(),
            )
          : null,
    );
  }
}
