import 'package:flutter/material.dart';

class AgeDobField extends StatefulWidget {
  final TextEditingController dobController;
  final TextEditingController ageController;

  const AgeDobField({
    super.key,
    required this.dobController,
    required this.ageController,
  });

  @override
  State<AgeDobField> createState() => _AgeDobFieldState();
}

class _AgeDobFieldState extends State<AgeDobField> {
  // Future<void> _selectDate(BuildContext context) async {
  //   DateTime now = DateTime.now();
  //   DateTime? picked = await showDatePicker(
  //     context: context,
  //     initialDate: DateTime(now.year - 30, now.month, now.day),
  //     firstDate: DateTime(1900),
  //     lastDate: now,
  //   );
  //
  //   if (picked != null) {
  //     widget.dobController.text = picked.toIso8601String().split('T')[0];
  //
  //     final age =
  //         now.year -
  //         picked.year -
  //         ((now.month < picked.month ||
  //                 (now.month == picked.month && now.day < picked.day))
  //             ? 1
  //             : 0);
  //
  //     widget.ageController.text = age.toString();
  //     setState(() {});
  //   }
  // }
  Future<void> _selectDate(BuildContext context) async {
    DateTime now = DateTime.now();

    // ✅ If DOB already selected, use it for initialDate
    DateTime initialDate;
    try {
      initialDate = widget.dobController.text.isNotEmpty
          ? DateTime.parse(widget.dobController.text)
          : DateTime(now.year - 30, now.month, now.day);
    } catch (_) {
      initialDate = DateTime(now.year - 30, now.month, now.day);
    }

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked != null) {
      widget.dobController.text = picked.toIso8601String().split('T')[0];

      final age =
          now.year -
          picked.year -
          ((now.month < picked.month ||
                  (now.month == picked.month && now.day < picked.day))
              ? 1
              : 0);

      widget.ageController.text = age.toString();
      setState(() {});
    }
  }

  void _onAgeChanged(String value) {
    if (value.isEmpty) return;
    final age = int.tryParse(value);
    if (age != null) {
      final now = DateTime.now();
      // ✅ Keep current month & day
      final dob = DateTime(now.year - age, now.month, now.day);
      widget.dobController.text = dob.toIso8601String().split('T')[0];
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: widget.dobController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Date of Birth',
              labelStyle: TextStyle(color: Colors.black),
              // prefixIcon: const Icon(Icons.calendar_today),
              prefixIcon: const Icon(Icons.date_range),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
              ),

              // Focus border (when typing)
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: Color(0xFFBF955E), width: 1.5),
              ),

              // Default border (fallback)
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
            onTap: () => _selectDate(context),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 120,
          child: TextField(
            cursorColor: Color(0xFFBF955E),
            controller: widget.ageController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Age',
              labelStyle: TextStyle(color: Colors.black),
              prefixIcon: Icon(Icons.person_outline, color: Colors.black),

              // Normal border
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
              ),

              // Focus border (when typing)
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: Color(0xFFBF955E), width: 1.5),
              ),

              // Default border (fallback)
              border: OutlineInputBorder(
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
