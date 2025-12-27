import 'package:flutter/material.dart';

const Color customGold = Color(0xFFBF955E);
const Color backgroundColor = Color(0xFFFFF7E6);
const Color cardColor = Colors.white;

const TextStyle sectionTitleStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: Colors.black87,
);

const TextStyle cardTitleStyle = TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w600,
  color: Colors.black87,
);

const TextStyle cardValueStyle = TextStyle(
  fontSize: 26,
  fontWeight: FontWeight.bold,
  color: Colors.black87,
);

// ======================================================
// TOGGLE BUTTON
// ======================================================
Widget buildToggle(String label, bool active, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: active
            ? const LinearGradient(
                colors: [Color(0xFFF5D6A2), Color(0xFFEEC98F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFFFF3E0), Color(0xFFFFF3E0)],
              ),
        border: Border.all(
          color: active ? const Color(0xFF886638) : Colors.brown.shade300,
          width: active ? 1.8 : 1.2,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: Colors.brown.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.brown.shade800 : Colors.brown.shade600,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

// ======================================================
// SECTION TITLE
// ======================================================
Widget buildSectionTitle(String title) => Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [Text(title, style: sectionTitleStyle)],
);

// ======================================================
// RESPONSIVE GRID (IMPORTANT FIX)
// ======================================================
Widget buildGrid(List<Widget> cards) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;

      int columns;
      if (width >= 1400) {
        columns = 5;
      } else if (width >= 1100) {
        columns = 4;
      } else if (width >= 800) {
        columns = 3;
      } else {
        columns = 2;
      }

      const spacing = 16.0;

      double itemWidth = (width - (spacing * (columns - 1))) / columns;

      // clamp to avoid over-stretching
      itemWidth = itemWidth.clamp(150, 260);

      return Wrap(
        alignment: WrapAlignment.center, // ⭐ center last row
        runAlignment: WrapAlignment.center,
        spacing: spacing,
        runSpacing: spacing,
        children: cards
            .map((card) => SizedBox(width: itemWidth, child: card))
            .toList(),
      );
    },
  );
}

// ======================================================
// METRIC CARD (CENTERED FIX)
// ======================================================
Widget buildMetricCard(String title, String value, IconData icon) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.shade300,
          offset: const Offset(0, 5),
          blurRadius: 8,
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min, // ⭐ REQUIRED FOR CENTERING
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: customGold, size: 28),
            const SizedBox(width: 8),
            Text(
              title,
              style: cardTitleStyle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(value, style: cardValueStyle, textAlign: TextAlign.center),
      ],
    ),
  );
}
