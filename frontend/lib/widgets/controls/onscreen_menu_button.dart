import 'package:flutter/material.dart';

class OnScreenMenuButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color? disabledColor;

  const OnScreenMenuButton({super.key, 
    required this.icon,
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
        icon: Icon(
          icon,
          color: onPressed == null
              ? (disabledColor ?? Colors.grey)
              : (isActive ? activeColor : Colors.white70),
        ),
        onPressed: onPressed,
        tooltip: tooltip,
        splashRadius: 24,
      ),
    );
  }
}
