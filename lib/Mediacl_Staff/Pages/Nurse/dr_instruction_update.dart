import 'package:flutter/material.dart';

class InstructionTile extends StatefulWidget {
  final String instruction;
  final String time;
  final bool isCompleted;
  final Future<void> Function() onComplete;

  const InstructionTile({
    super.key,
    required this.instruction,
    required this.time,
    required this.isCompleted,
    required this.onComplete,
  });

  @override
  State<InstructionTile> createState() => _InstructionTileState();
}

class _InstructionTileState extends State<InstructionTile> {
  bool _updating = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.isCompleted
            ? Colors.green.withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// LEFT STATUS CIRCLE
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.isCompleted
                    ? Colors.green
                    : Colors.orange.shade400,
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.isCompleted ? Icons.check : Icons.schedule,
                color: Colors.white,
                size: 20,
              ),
            ),

            const SizedBox(width: 14),

            /// CENTER CONTENT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.instruction,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      decoration: widget.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.time,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            /// RIGHT ACTION
            widget.isCompleted
                ? const Icon(Icons.verified, color: Colors.green, size: 26)
                : _updating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Checkbox(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    value: false,
                    onChanged: (_) async {
                      setState(() => _updating = true);
                      await widget.onComplete();
                      setState(() => _updating = false);
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
