import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceSearchDialog extends StatefulWidget {
  const VoiceSearchDialog({
    super.key,
    required this.onClose,
    required this.onResult,
  });

  final VoidCallback onClose;
  final ValueChanged<String> onResult;

  @override
  State<VoiceSearchDialog> createState() => _VoiceSearchDialogState();
}

class _VoiceSearchDialogState extends State<VoiceSearchDialog>
    with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _listening = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    _speech = stt.SpeechToText();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startListening();
  }

  Future<void> _startListening() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'listening') {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
        }
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _errorMessage = error.errorMsg;
          _listening = false;
        });
      },
    );

    if (!mounted) return;

    if (available) {
      setState(() => _listening = true);

      _speech.listen(
        listenMode: stt.ListenMode.confirmation,
        onResult: (result) {
          if (!mounted) return;

          widget.onResult(result.recognizedWords);

          if (result.finalResult) {
            _stopListening();
          }
        },
      );
    } else {
      setState(() {
        _errorMessage = 'Speech recognition not available';
        _listening = false;
      });
    }
  }

  void _stopListening() {
    _speech.stop();
    _pulseController.stop();
    widget.onClose();
  }

  @override
  void dispose() {
    _speech.stop();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage.isNotEmpty) {
      return IconButton(
        icon: const Icon(Icons.mic_off, color: Colors.grey),
        onPressed: widget.onClose,
      );
    }

    return AvatarGlow(
      animate: _listening,
      glowColor: Colors.red,
      duration: const Duration(milliseconds: 2000),
      child: GestureDetector(
        onTap: _stopListening,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _listening ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                  border: Border.all(color: const Color(0xFFE0FFF2), width: 6),
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 20),
              ),
            );
          },
        ),
      ),
    );
  }
}
