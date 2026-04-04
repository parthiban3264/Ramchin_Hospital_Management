import 'package:flutter/material.dart';
//
// class AnimatedTypewriterText extends StatefulWidget {
//   final String text;
//   final double fontSize;
//
//   const AnimatedTypewriterText({
//     super.key,
//     required this.text,
//     this.fontSize = 15.5,
//   });
//
//   @override
//   State<AnimatedTypewriterText> createState() => _AnimatedTypewriterTextState();
// }
//
// class _AnimatedTypewriterTextState extends State<AnimatedTypewriterText> {
//   String displayed = '';
//   int i = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     _startTyping();
//   }
//
//   void _startTyping() async {
//     while (i < widget.text.length) {
//       await Future.delayed(const Duration(milliseconds: 20));
//
//       if (!mounted) return;
//
//       setState(() {
//         displayed += widget.text[i];
//         i++;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Text(
//       displayed,
//       textAlign: TextAlign.center,
//       style: TextStyle(
//         fontSize: widget.fontSize,
//         height: 1.6,
//         color: Colors.black87,
//         letterSpacing: 0.2,
//       ),
//     );
//   }
// }

class AnimatedTypewriterText extends StatefulWidget {
  final String text;
  final double fontSize;
  final int delay; // ⏳ NEW

  const AnimatedTypewriterText({
    super.key,
    required this.text,
    this.fontSize = 15.5,
    this.delay = 0, // default no delay
  });

  @override
  State<AnimatedTypewriterText> createState() => _AnimatedTypewriterTextState();
}

class _AnimatedTypewriterTextState extends State<AnimatedTypewriterText> {
  String displayed = '';
  int i = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() async {
    // ⏳ WAIT BEFORE START
    await Future.delayed(Duration(milliseconds: widget.delay));

    while (i < widget.text.length) {
      await Future.delayed(const Duration(milliseconds: 20));

      if (!mounted) return;

      setState(() {
        displayed += widget.text[i];
        i++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      displayed,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: widget.fontSize,
        height: 1.4,
        color: Colors.black87,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
    );
  }
}
