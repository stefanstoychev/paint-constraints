import 'package:flutter/material.dart';
import 'package:frontend/models/shape_data.dart';

class LinkButton extends StatelessWidget {
  final String label;
  final ColorComponent component;
  final double offsetValue;
  final void Function(ColorComponent, double) onPressed;

  const LinkButton({
    super.key,
    required this.label,
    required this.component,
    required this.offsetValue,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => onPressed(component, offsetValue),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        textStyle: const TextStyle(fontSize: 10),
      ),
      child: Text(label),
    );
  }
}
