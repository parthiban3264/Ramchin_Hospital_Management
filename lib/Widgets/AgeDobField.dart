import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AgeDobField extends StatefulWidget {
  final TextEditingController dobController;
  final TextEditingController ageController;

  /// 🔹 Focus + submit handling
  final FocusNode? focusNode;
  final VoidCallback? onSubmitted;

  const AgeDobField({
    super.key,
    required this.dobController,
    required this.ageController,
    this.focusNode,
    this.onSubmitted,
  });

  @override
  State<AgeDobField> createState() => _AgeDobFieldState();
}

class _AgeDobFieldState extends State<AgeDobField> {
  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();

    DateTime initialDate;
    try {
      initialDate = widget.dobController.text.isNotEmpty
          ? DateTime.parse(widget.dobController.text)
          : DateTime(now.year - 30, now.month, now.day);
    } catch (_) {
      initialDate = DateTime(now.year - 30, now.month, now.day);
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked != null) {
      widget.dobController.text = picked.toIso8601String().split('T')[0];

      final int age =
          now.year -
          picked.year -
          ((now.month < picked.month ||
                  (now.month == picked.month && now.day < picked.day))
              ? 1
              : 0);

      widget.ageController.text = age.toString();

      /// 🔥 Move to NEXT field (not force focus here)
      widget.onSubmitted?.call();

      setState(() {});
    }
  }

  void _onAgeChanged(String value) {
    if (value.isEmpty) {
      widget.dobController.clear();
      return;
    }

    final int? age = int.tryParse(value);
    if (age == null || age < 0 || age > 120) return;

    final now = DateTime.now();
    final dob = DateTime(now.year - age, now.month, now.day);

    widget.dobController.text = dob.toIso8601String().split('T')[0];
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        /// 🔹 DOB FIELD
        Expanded(
          child: TextField(
            controller: widget.dobController,
            readOnly: true,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => widget.onSubmitted?.call(),
            decoration: InputDecoration(
              labelText: 'Date of Birth',
              prefixIcon: const Icon(Icons.date_range),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: Color(0xFFBF955E), width: 1.5),
              ),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
            onTap: () => _selectDate(context),
          ),
        ),

        const SizedBox(width: 10),

        /// 🔹 AGE FIELD
        SizedBox(
          width: 120,
          child: TextField(
            focusNode: widget.focusNode,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => widget.onSubmitted?.call(),
            controller: widget.ageController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Age',
              prefixIcon: const Icon(Icons.person_outline),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: Color(0xFFBF955E), width: 1.5),
              ),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
            onChanged: _onAgeChanged,
          ),
        ),
      ],
    );
  }
}
