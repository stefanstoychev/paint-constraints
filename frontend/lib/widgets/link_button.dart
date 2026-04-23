import 'package:flutter/material.dart';
import 'package:frontend/models/color_relationship.dart';

class LinkButton extends StatelessWidget {
  final String label;
  final ColorRelationship relationship;
  final void Function(ColorRelationship) onPressed;
  final bool isActive;

  const LinkButton({
    super.key,
    required this.label,
    required this.relationship,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: OutlinedButton(
        onPressed: () => onPressed(relationship),
        style: OutlinedButton.styleFrom(
          backgroundColor: isActive ? Colors.blueAccent.withValues(alpha: 0.2) : Colors.transparent,
          foregroundColor: isActive ? Colors.blueAccent : Colors.white70,
          side: BorderSide(
            color: isActive ? Colors.blueAccent : Colors.white24,
            width: 1,
          ),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
