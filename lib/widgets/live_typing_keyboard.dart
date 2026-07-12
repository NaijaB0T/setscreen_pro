import 'package:flutter/material.dart';
import '../controllers/chat_controller.dart';

class LiveTypingKeyboard extends StatelessWidget {
  final ChatController controller;
  final bool isDarkMode;

  const LiveTypingKeyboard({
    super.key,
    required this.controller,
    required this.isDarkMode,
  });

  Widget _buildKey({
    required String label,
    required VoidCallback onTap,
    double flex = 1,
    Color? customColor,
    Color? customTextColor,
  }) {
    final defaultKeyColor = isDarkMode
        ? const Color(0xFF6B6B6D)
        : const Color(0xFFFCFCFE);
        
    final keyColor = customColor ?? defaultKeyColor;

    final defaultTextColor = isDarkMode ? Colors.white : Colors.black;
    final textColor = customTextColor ?? defaultTextColor;

    return Expanded(
      flex: flex.toInt(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
        height: 42,
        decoration: BoxDecoration(
          color: keyColor,
          borderRadius: BorderRadius.circular(5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              offset: const Offset(0, 1),
              blurRadius: 0.5,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(5),
            onTap: onTap,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Colors
    final keyboardBgColor = isDarkMode
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFD1D3D9);

    final specialKeyColor = isDarkMode
        ? const Color(0xFF4A4A4C)
        : const Color(0xFFB0B3BC);

    final sendKeyColor = controller.isGreenBubble
        ? const Color(0xFF34C759)
        : const Color(0xFF007AFF);

    // QWERTY Key Rows
    final row1 = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"];
    final row2 = ["A", "S", "D", "F", "G", "H", "J", "K", "L"];
    final row3 = ["Z", "X", "C", "V", "B", "N", "M"];

    return Container(
      color: keyboardBgColor,
      padding: const EdgeInsets.only(top: 8, bottom: 24, left: 3, right: 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1
          Row(
            children: row1
                .map((letter) => _buildKey(
                      label: letter,
                      onTap: () => controller.typeNextCharacter(),
                    ))
                .toList(),
          ),
          
          // Row 2
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: row2
                  .map((letter) => _buildKey(
                        label: letter,
                        onTap: () => controller.typeNextCharacter(),
                      ))
                  .toList(),
            ),
          ),
          
          // Row 3 (Shift, Z-M, Backspace)
          Row(
            children: [
              // Shift Key (simulates character typing too, for simplicity of intercepting taps)
              _buildKey(
                label: "⇧",
                customColor: specialKeyColor,
                onTap: () => controller.typeNextCharacter(),
                flex: 1.3,
              ),
              ...row3.map((letter) => _buildKey(
                    label: letter,
                    onTap: () => controller.typeNextCharacter(),
                  )),
              // Backspace Key (simulates character typing to maintain flow under script intercept)
              _buildKey(
                label: "⌫",
                customColor: specialKeyColor,
                onTap: () => controller.typeNextCharacter(),
                flex: 1.3,
              ),
            ],
          ),
          
          // Row 4 (123, Spacebar, Return/Send)
          Row(
            children: [
              _buildKey(
                label: "123",
                customColor: specialKeyColor,
                onTap: () => controller.typeNextCharacter(),
                flex: 2,
              ),
              _buildKey(
                label: "space",
                onTap: () => controller.typeNextCharacter(),
                flex: 5,
              ),
              _buildKey(
                label: "return",
                customColor: controller.isMessageFullyTyped
                    ? sendKeyColor
                    : specialKeyColor,
                customTextColor: controller.isMessageFullyTyped
                    ? Colors.white
                    : (isDarkMode ? Colors.white60 : Colors.black45),
                onTap: () {
                  if (controller.isMessageFullyTyped) {
                    controller.sendMessage();
                  } else {
                    // Tap return when not fully typed still advances text to be robust
                    controller.typeNextCharacter();
                  }
                },
                flex: 2.5,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
