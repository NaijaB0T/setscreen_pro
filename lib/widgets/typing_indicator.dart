import 'dart:math';
import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  final bool isDarkMode;

  const TypingIndicator({
    super.key,
    required this.isDarkMode,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Calculate a sine wave offset for each dot based on time and index
        final double delay = index * 0.2;
        final double value = (sin((_controller.value * 2 * pi) - delay) + 1) / 2;
        
        return Transform.translate(
          offset: Offset(0, -value * 6), // bounce height
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: widget.isDarkMode
                  ? Colors.white.withValues(alpha: 0.4 + (value * 0.4))
                  : Colors.black.withValues(alpha: 0.2 + (value * 0.4)),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  static const double pi = 3.1415926535897932;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = widget.isDarkMode
        ? const Color(0xFF252528)
        : const Color(0xFFE5E5EA);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
          ],
        ),
      ),
    );
  }
}
