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
    return ElevatedButton(
      onPressed: () => onPressed(relationship),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.blueAccent : null,
        foregroundColor: isActive ? Colors.white : null,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        textStyle: const TextStyle(fontSize: 10),
      ),
      child: Text(label),
    );
  }
}
