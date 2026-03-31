import 'package:flutter/material.dart';

class AnimatedDotsText extends StatefulWidget {
  final String text;
  const AnimatedDotsText({super.key, required this.text});

  @override
  State<AnimatedDotsText> createState() => _AnimatedDotsTextState();
}

class _AnimatedDotsTextState extends State<AnimatedDotsText> {
  int _dotCount = 1;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _dotCount = (_dotCount % 3) + 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      "${widget.text}${" ." * _dotCount}",
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}
