import 'package:flutter/material.dart';

class OnscreenMenuButtonLetter extends StatelessWidget {
  final String letter;
  final bool isActive;
  final Color activeColor;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color? disabledColor;

  const OnscreenMenuButtonLetter({
    required this.letter,
    required this.isActive,
    required this.activeColor,
    required this.onPressed,
    required this.tooltip,
    this.disabledColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? activeColor.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Text(
          letter,
          style: TextStyle(
            color: onPressed == null
                ? (disabledColor ?? Colors.grey)
                : (isActive ? activeColor : Colors.white70),
          ),
        ),
        onPressed: onPressed,
        tooltip: tooltip,
        splashRadius: 24,
      ),
    );
  }
}
