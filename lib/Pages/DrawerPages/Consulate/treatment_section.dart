import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const Color primaryColor = Color(0xFFBF955E);

class TreatmentSection extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final TextEditingController titleController;
  final TextEditingController notesController;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<Map<String, dynamic>> staffList;
  final Set<String> selectedStaffIds;

  // FIX: add required pickDate function with correct signature
  final Future<void> Function(BuildContext context, bool isStart) pickDate;

  const TreatmentSection({
    super.key,
    required this.enabled,
    required this.onToggle,
    required this.titleController,
    required this.notesController,
    required this.startDate,
    required this.endDate,
    required this.staffList,
    required this.selectedStaffIds,
    required this.pickDate, // make it required
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Treatment',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                Switch(
                  value: enabled,
                  onChanged: onToggle,
                  activeColor: primaryColor,
                ),
              ],
            ),
            if (enabled) ...[
              const SizedBox(height: 10),
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Treatment Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor),
                  ),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Enter Treatment Title'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Treatment Notes',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => pickDate(context, true),
                      child: Text(
                        startDate == null
                            ? "Select Start Date"
                            : "Start: ${DateFormat('MMM dd, yyyy').format(startDate!)}",
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => pickDate(context, false),
                      child: Text(
                        endDate == null
                            ? "Select End Date"
                            : "End: ${DateFormat('MMM dd, yyyy').format(endDate!)}",
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Assign Staff',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: staffList.length,
                  itemBuilder: (context, i) {
                    final staff = staffList[i];
                    final isSelected = selectedStaffIds.contains(staff['id']);
                    return GestureDetector(
                      onTap: () {
                        if (isSelected) {
                          selectedStaffIds.remove(staff['id']);
                        } else {
                          selectedStaffIds.add(staff['id']);
                        }
                      },
                      child: Container(
                        width: 110,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryColor.withOpacity(0.8)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryColor),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              staff['name'] ?? 'Unknown',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "ID: ${staff['id'] ?? '-'}",
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white70
                                    : Colors.grey[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
