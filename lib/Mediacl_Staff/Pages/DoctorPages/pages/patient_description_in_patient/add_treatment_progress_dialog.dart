import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../Services/prescription_service.dart';

class AddTreatmentProgressDialog extends StatefulWidget {
  final Map<String, dynamic> consultation;
  final String role;
  final int mode; // O dr, 1 nurse
  final VoidCallback? onSubmitted;

  const AddTreatmentProgressDialog({
    super.key,
    required this.consultation,
    required this.role,
    this.onSubmitted,
    required this.mode,
  });

  @override
  State<AddTreatmentProgressDialog> createState() =>
      _AddTreatmentProgressDialogState();
}

class _AddTreatmentProgressDialogState extends State<AddTreatmentProgressDialog>
    with SingleTickerProviderStateMixin {
  static const Color _gold = Color(0xFFBA8C50);

  late TabController _tabController;
  bool _isSubmitting = false;

  // 🔑 Separate controllers
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _instructionController = TextEditingController();

  final PrescriptionService _service = PrescriptionService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // If NOT doctor and trying to open Instruction tab
      if (widget.mode != 0 && _tabController.index == 1) {
        // Revert to Notes tab
        _tabController.index = 0;

        showTopWarning(context, 'Access only for Doctor');
      }
    });
  }

  void showTopWarning(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);

    messenger.clearMaterialBanners();

    messenger.showMaterialBanner(
      MaterialBanner(
        backgroundColor: Colors.orange.shade100,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        content: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 26,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              messenger.clearMaterialBanners();
            },
            child: const Text('OK', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    _instructionController.dispose();
    super.dispose();
  }

  // ───────────────────────── Submit ─────────────────────────

  Future<void> _submit() async {
    if (widget.mode != 0 && _tabController.index == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access only for Doctor'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final isNotesTab = _tabController.index == 0;

    final text = isNotesTab
        ? _notesController.text.trim()
        : _instructionController.text.trim();

    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final doctorId = int.parse(prefs.getString('userId') ?? '0');

      final admissionId = widget.consultation['Admission'][0]['id'].toString();

      // 🔒 Fixed current date & time (12h)
      final now = DateTime.now();
      final dateKey = DateFormat('dd-MM-yyyy').format(now);
      final time = DateFormat('hh:mm a').format(now);

      if (_tabController.index == 0) {
        final note = widget.mode == 0 ? 'drNotes' : 'nurseNotes';
        await _service.updateAdmissionNotes(
          admissionId: int.parse(admissionId.toString()),
          notes: note,
          notesByDate: {
            dateKey: [
              {'time': time, 'text': text},
            ],
          },
        );
      } else {
        await _service.createDoctorInstruction(
          admissionId: int.parse(admissionId.toString()),
          doctorId: doctorId,
          instruction: text,
        );
      }

      widget.onSubmitted?.call();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('error $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ───────────────────────── UI ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          _dragHandle(),
          _title(),

          /// Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              // padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade700,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(14),
              ),
              tabs: const [
                Tab(text: 'Notes'),
                Tab(text: 'Instruction'),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              children: [
                _fixedDateTime(now),
                const SizedBox(height: 16),
                _notesField(),
                const SizedBox(height: 24),
                _submitButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Widgets ─────────────────────────

  Widget _fixedDateTime(DateTime now) {
    return Row(
      children: [
        Expanded(
          child: _infoBox(
            Icons.calendar_today,
            DateFormat('dd MMM yyyy').format(now),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _infoBox(Icons.access_time, DateFormat('hh:mm a').format(now)),
        ),
      ],
    );
  }

  Widget _notesField() {
    return TextField(
      controller: _tabController.index == 0
          ? _notesController
          : _instructionController,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: _tabController.index == 0
            ? 'Enter treatment notes'
            : 'Enter doctor instruction',
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _gold, width: 1.5),
        ),
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _gold,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isSubmitting
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  'Save',
                  key: ValueKey('text'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _dragHandle() => Container(
    width: 36,
    height: 4,
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      borderRadius: BorderRadius.circular(2),
    ),
  );

  Widget _title() => Column(
    children: [
      const Text(
        'Add Treatment Progress',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      Text(
        widget.role.toUpperCase(),
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
    ],
  );

  Widget _infoBox(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _gold),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}
