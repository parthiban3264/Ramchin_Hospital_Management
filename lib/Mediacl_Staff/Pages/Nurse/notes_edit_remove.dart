import 'package:flutter/material.dart';
import '../../../Services/prescription_service.dart';

class BottomOpenNotes extends StatefulWidget {
  final dynamic rawNotes;
  final int admitId;
  final int mode; // 0 = doctor, 1 = nurse
  final String rawNotesKey;

  const BottomOpenNotes({
    super.key,
    required this.rawNotes,
    required this.admitId,
    required this.mode,
    required this.rawNotesKey,
  });

  @override
  State<BottomOpenNotes> createState() => _BottomOpenNotesState();
}

class _BottomOpenNotesState extends State<BottomOpenNotes> {
  late Map<String, dynamic> notesMap;
  late List<String> sortedDays;

  final PrescriptionService _service = PrescriptionService();

  // @override
  // void initState() {
  //   super.initState();
  //
  //   notesMap = widget.rawNotes is Map
  //       ? Map<String, dynamic>.from(widget.rawNotes)
  //       : {};
  //
  //   sortedDays = notesMap.keys.toList()
  //     ..sort((a, b) {
  //       DateTime parse(String d) {
  //         final p = d.split('-');
  //         return DateTime(
  //           int.tryParse(p[2]) ?? 0,
  //           int.tryParse(p[1]) ?? 1,
  //           int.tryParse(p[0]) ?? 1,
  //         );
  //       }
  //
  //       return parse(b).compareTo(parse(a));
  //     });
  // }

  @override
  void initState() {
    super.initState();

    if (widget.rawNotesKey == 'drInstruction' && widget.rawNotes is List) {
      notesMap = _buildInstructionNotes(widget.rawNotes);
    } else if (widget.rawNotes is Map) {
      notesMap = Map<String, dynamic>.from(widget.rawNotes);
    } else {
      notesMap = {};
    }

    sortedDays = notesMap.keys.toList()
      ..sort((a, b) {
        DateTime parse(String d) {
          final p = d.split('-');
          return DateTime(
            int.tryParse(p[2]) ?? 0,
            int.tryParse(p[1]) ?? 1,
            int.tryParse(p[0]) ?? 1,
          );
        }

        return parse(b).compareTo(parse(a));
      });
  }

  Map<String, List<Map<String, dynamic>>> _buildInstructionNotes(
    List<dynamic> instructions,
  ) {
    final Map<String, List<Map<String, dynamic>>> map = {};

    for (final item in instructions) {
      final createdAt = DateTime.tryParse(item['createdAt'] ?? '');
      if (createdAt == null) continue;

      final day =
          '${createdAt.day.toString().padLeft(2, '0')}-'
          '${createdAt.month.toString().padLeft(2, '0')}-'
          '${createdAt.year}';

      map.putIfAbsent(day, () => []);

      map[day]!.add({
        'id': item['id'],
        'text': item['instruction'] ?? '',
        'time':
            '${createdAt.hour.toString().padLeft(2, '0')}:'
            '${createdAt.minute.toString().padLeft(2, '0')}',
        'status': item['status'],
      });
    }

    return map;
  }

  /// 🔐 PERMISSION
  bool get canEditDelete {
    return (widget.mode == 0 && widget.rawNotesKey == 'drNotes' ||
            widget.rawNotesKey == 'drInstruction') ||
        (widget.mode == 1 && widget.rawNotesKey == 'notes');
  }

  /// 🔁 Convert reversed index → real index
  int _realIndex(String day, int reversedIndex) {
    return notesMap[day].length - 1 - reversedIndex;
  }

  /// ✏️ EDIT NOTE
  void _editNote(String day, int reversedIndex, String oldText) async {
    final controller = TextEditingController(text: oldText);

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Edit Note',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Update note...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      final realIndex = _realIndex(day, reversedIndex);
      final text = controller.text.trim();

      /// Optimistic UI update
      setState(() {
        notesMap[day][realIndex]['text'] = text;
      });
      widget.rawNotesKey == 'drInstruction'
          ? await _service.editInstruction(
              admissionId: widget.admitId,
              instructionId: notesMap[day][realIndex]['id'],
              newText: text,
            )
          : await _service.editNote(
              admissionId: widget.admitId,
              noteType: widget.rawNotesKey,
              date: day,
              index: realIndex,
              newText: text,
            );
    }
  }

  /// 🗑 DELETE NOTE
  // void _deleteNote(String day, int reversedIndex) async {
  //   final confirm = await showDialog<bool>(
  //     context: context,
  //     builder: (_) => AlertDialog(
  //       title: Text(
  //         'Delete ${widget.rawNotesKey == 'drInstruction' ? 'Instructions' : 'Note'}?',
  //       ),
  //       content: const Text('This action cannot be undone.'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, false),
  //           child: const Text('Cancel'),
  //         ),
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, true),
  //           child: const Text('Delete', style: TextStyle(color: Colors.red)),
  //         ),
  //       ],
  //     ),
  //   );
  //
  //   if (confirm == true) {
  //     final realIndex = _realIndex(day, reversedIndex);
  //
  //     /// Optimistic UI update
  //     setState(() {
  //       notesMap[day].removeAt(realIndex);
  //       if (notesMap[day].isEmpty) {
  //         notesMap.remove(day);
  //         sortedDays.remove(day);
  //       }
  //     });
  //     print(notesMap);
  //     print(widget.rawNotesKey);
  //     print('index ${notesMap[day][realIndex]['id']}');
  //
  //     widget.rawNotesKey == 'drInstruction'
  //         ? await _service.deleteInstruction(
  //             admissionId: widget.admitId,
  //             instructionId: notesMap[day][realIndex]['id'],
  //           )
  //         : await _service.deleteNote(
  //             admissionId: widget.admitId,
  //             noteType: widget.rawNotesKey,
  //             date: day,
  //             index: realIndex,
  //           );
  //   }
  // }

  void _deleteNote(String day, int reversedIndex) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Delete ${widget.rawNotesKey == 'drInstruction' ? 'Instruction' : 'Note'}?',
        ),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final realIndex = _realIndex(day, reversedIndex);

    /// ✅ SAVE ID BEFORE REMOVING
    final deletedItem = notesMap[day][realIndex];
    final instructionId = deletedItem['id'];

    /// Optimistic UI update
    setState(() {
      notesMap[day].removeAt(realIndex);
      if (notesMap[day].isEmpty) {
        notesMap.remove(day);
        sortedDays.remove(day);
      }
    });

    /// API CALL
    if (widget.rawNotesKey == 'drInstruction') {
      await _service.deleteInstruction(
        admissionId: widget.admitId,
        instructionId: instructionId,
      );
    } else {
      await _service.deleteNote(
        admissionId: widget.admitId,
        noteType: widget.rawNotesKey,
        date: day,
        index: realIndex,
      );
    }
  }

  /// 🧱 NOTE CARD UI
  Widget _noteCard({
    required String text,
    required String time,
    required String status,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final bool showStatus =
        widget.rawNotesKey == 'drInstruction' && status.isNotEmpty;

    final Color statusColor = status == 'COMPLETED'
        ? Colors.green
        : status == 'PENDING'
        ? Colors.orange
        : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TEXT + STATUS
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    text.isNotEmpty ? text : 'No note added',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                      color: Colors.grey[900],
                    ),
                  ),
                ),

                /// STATUS BADGE (Instruction only)
                if (showStatus)
                  Container(
                    margin: const EdgeInsets.only(left: 10, top: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// TIME
                if (time.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                /// ACTIONS
                if (((widget.rawNotesKey == 'drNotes' ||
                            widget.rawNotesKey == 'notes') &&
                        canEditDelete) ||
                    (widget.rawNotesKey == 'drInstruction' &&
                        status == 'PENDING' &&
                        canEditDelete))
                  Row(
                    children: [
                      _actionIcon(
                        icon: Icons.edit_outlined,
                        color: Colors.blueGrey,
                        onTap: onEdit,
                      ),
                      const SizedBox(width: 8),
                      _actionIcon(
                        icon: Icons.delete_outline,
                        color: Colors.redAccent,
                        onTap: onDelete,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFFF2F3F7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            /// DRAG HANDLE
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(12),
              ),
            ),

            /// TITLE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Text(
                    widget.rawNotesKey == 'drInstruction'
                        ? 'Instructions'
                        : 'Notes',

                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(),

            /// NOTES LIST
            Expanded(
              child: sortedDays.isEmpty
                  ? const Center(child: Text('No notes available'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: sortedDays.length,
                      itemBuilder: (_, i) {
                        final day = sortedDays[i];
                        final notes = List<Map<String, dynamic>>.from(
                          notesMap[day],
                        ).reversed.toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              day,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...notes.asMap().entries.map((e) {
                              return _noteCard(
                                text: e.value['text'] ?? '',
                                time: e.value['time'] ?? '',
                                status: e.value['status'] ?? '',
                                onEdit: () =>
                                    _editNote(day, e.key, e.value['text']),

                                onDelete: () => _deleteNote(day, e.key),
                              );
                            }),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
