import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const Color primaryColor = Color(0xFFBF955E);
const Color cardBgColor = Color(0xFFF8F8F8);
const Color selectedColor = Color(0xFFBF955E);

class TestingScanningSection extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final TextEditingController titleController;
  final DateTime? scheduleDate;
  final void Function(BuildContext) pickDate;
  final List<Map<String, dynamic>> staffList;
  final Set<String> selectedStaffIds;
  final ValueChanged<Set<String>> onStaffChanged;

  const TestingScanningSection({
    super.key,
    required this.enabled,
    required this.onToggle,
    required this.titleController,
    required this.scheduleDate,
    required this.pickDate,
    required this.staffList,
    required this.selectedStaffIds,
    required this.onStaffChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 12),
      color: cardBgColor,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.science, color: primaryColor, size: 28),
                const SizedBox(width: 8),
                const Text(
                  'Testing / Scanning',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                const Spacer(),
                Transform.scale(
                  scale: 1.1,
                  child: Switch.adaptive(
                    value: enabled,
                    onChanged: onToggle,
                    activeColor: primaryColor,
                  ),
                ),
              ],
            ),
            if (enabled) ...[
              const SizedBox(height: 16),
              // Title / Notes
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: "Title / Notes",
                  prefixIcon: const Icon(Icons.description),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Schedule Date Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: primaryColor),
                    foregroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => pickDate(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        scheduleDate == null
                            ? "Select Schedule Date"
                            : "Scheduled: ${DateFormat.yMMMd().format(scheduleDate!)}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Staff Selection
              if (staffList.isNotEmpty) ...[
                const Text(
                  "Assign Staff",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: staffList.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final staff = staffList[index];
                      final isSelected = selectedStaffIds.contains(staff['id']);
                      return GestureDetector(
                        onTap: () {
                          final newSet = Set<String>.from(selectedStaffIds);
                          if (isSelected) {
                            newSet.remove(staff['id']);
                          } else {
                            newSet.add(staff['id']);
                          }
                          onStaffChanged(newSet);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          width: 120,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isSelected ? selectedColor : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: primaryColor, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                staff['name'] ?? 'Unknown',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "ID: ${staff['id'] ?? '-'}",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isSelected
                                      ? Colors.white70
                                      : Colors.black54,
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
          ],
        ),
      ),
    );
  }
}
