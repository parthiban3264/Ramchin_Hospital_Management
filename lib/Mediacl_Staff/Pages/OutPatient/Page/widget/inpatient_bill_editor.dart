import 'package:flutter/material.dart';

import '../../../../../Services/charge_Service.dart';
import '../../../../../Services/payment_service.dart';

class InpatientEditBill {
  final BuildContext context;
  final Map<String, dynamic> admission;

  final Map<String, dynamic>? Function(Map<String, dynamic>, DateTime)
  getWardForCharge;

  final Map<String, dynamic>? Function(Map<String, dynamic>, DateTime)
  getStaffForCharge;

  final String Function(String?) getStaffDisplayName;
  final int paymentId;
  final Future<void> Function() onRefresh;

  InpatientEditBill({
    required this.context,
    required this.admission,
    required this.paymentId,
    required this.getWardForCharge,
    required this.getStaffForCharge,
    required this.getStaffDisplayName,
    required this.onRefresh,
  });

  // ───────────────── ENTRY ─────────────────

  void open(String category, List<Map<String, dynamic>> items) {
    print('category $category');
    if (category == 'Room Rent') {
      _editRoomRent(items);
    } else if (category == 'Doctor Fee') {
      _editDoctorFee(items);
    } else if (category == 'Nurse Fee') {
      _editNurseFee(items);
    } else {
      _editOtherCharges(items);
    }
  }

  // ───────────────── BASE SHEET ─────────────────

  void _openSheet({required String title, required List<Widget> children}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// DRAG HANDLE
                Container(
                  width: 42,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                /// HEADER
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    IconButton(
                      splashRadius: 20,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const Divider(height: 24),

                /// CONTENT
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(children: children),
                  ),
                ),

                const SizedBox(height: 16),

                /// BOTTOM ACTION
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _editTile({
    required String title,
    required num amount,
    required VoidCallback onEdit,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          /// INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹$amount',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),

          /// EDIT
          IconButton(
            splashRadius: 20,
            icon: Icon(
              Icons.edit_rounded,
              size: 20,
              color: Colors.blue.shade600,
            ),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }

  // ───────────────── ROOM RENT ─────────────────

  void _editRoomRent(List<Map<String, dynamic>> items) {
    _openSheet(
      title: 'Edit Room Rent',
      children: items.map((c) {
        final ward = getWardForCharge(
          admission,
          DateTime.parse(c['createdAt']),
        );

        return _editTile(
          title: '${ward?['name']} - ${ward?['type']} • Bed ${ward?['bedNo']}',
          amount: c['amount'],
          onEdit: () => _editAmount(c),
        );
      }).toList(),
    );
  }

  // ───────────────── DOCTOR ─────────────────

  void _editDoctorFee(List<Map<String, dynamic>> items) {
    _openSheet(
      title: 'Edit Doctor Charges',
      children: items.map((c) {
        final staff = getStaffForCharge(
          admission,
          DateTime.parse(c['createdAt']),
        );

        return _editTile(
          title: getStaffDisplayName(staff?['doctor']),
          amount: c['amount'],
          onEdit: () => _editAmount(c),
        );
      }).toList(),
    );
  }

  // ───────────────── NURSE ─────────────────

  void _editNurseFee(List<Map<String, dynamic>> items) {
    _openSheet(
      title: 'Edit Nursing Charges',
      children: items.map((c) {
        final staff = getStaffForCharge(
          admission,
          DateTime.parse(c['createdAt']),
        );

        return _editTile(
          title: getStaffDisplayName(staff?['nurse']),
          amount: c['amount'],
          onEdit: () => _editAmount(c),
        );
      }).toList(),
    );
  }

  // ───────────────── OTHERS ─────────────────

  void _editOtherCharges(List<Map<String, dynamic>> items) {
    _openSheet(
      title: 'Edit Other Charges',
      children: items.map((c) {
        return _editTile(
          title: c['title'] ?? c['description'] ?? 'Other Charge',
          amount: c['amount'],
          onEdit: () => _editAmount(c),
        );
      }).toList(),
    );
  }

  // ───────────────── EDIT DIALOG ─────────────────

  void _editAmount(Map<String, dynamic> charge) {
    final currentAmount = num.tryParse(charge['amount'].toString()) ?? 0;
    final controller = TextEditingController(text: currentAmount.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            20,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              const Text(
                'Edit Amount',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              /// CURRENT AMOUNT CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Amount',
                      style: TextStyle(
                        color: Colors.blueGrey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹$currentAmount',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// INPUT
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Reduce To Amount',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  final typed = num.tryParse(value) ?? 0;

                  if (typed > currentAmount) {
                    controller.text = currentAmount.toString();
                    controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: controller.text.length),
                    );
                  }
                },
              ),

              const SizedBox(height: 24),

              /// ACTIONS
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Update'),
                      onPressed: () async {
                        final reduceAmount = num.tryParse(controller.text) ?? 0;

                        if (reduceAmount <= 0) {
                          _showError('Enter valid amount');
                          return;
                        }

                        Navigator.pop(context);
                        await _updateCharge(charge, reduceAmount);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ───────────────── API UPDATE ─────────────────

  Future<void> _updateCharge(Map<String, dynamic> charge, num decrement) async {
    ;
    try {
      // 🔽 Payment update
      await PaymentService().updateDecreasePayment(paymentId, {
        'decrementAmount': decrement,
        'chargeId': charge['id'],
      });
      await onRefresh();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount updated successfully')),
      );
    } catch (e) {
      _showError('Failed to update amount');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }
}
