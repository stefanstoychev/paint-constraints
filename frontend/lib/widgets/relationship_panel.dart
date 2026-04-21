import 'package:flutter/material.dart';
import 'package:frontend/models/color_component.dart';
import 'package:frontend/models/color_constraints.dart';
import 'package:frontend/models/color_relationship.dart';
import 'package:frontend/widgets/link_button.dart';

class RelationshipPanel extends StatelessWidget {
  const RelationshipPanel({
    super.key,
    required this.colorConstraints,
    required this.onRelationshipApplied,
    required this.onClearRelationships,
  });

  final ColorConstraints colorConstraints;
  final ValueChanged<ColorRelationship> onRelationshipApplied;
  final VoidCallback onClearRelationships;

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Positioned(
      top: isSmallScreen ? 70 : 20,
      right: isSmallScreen ? 10 : 20,
      left: isSmallScreen ? 10 : null,
      child: Card(
        color: Colors.black87,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Define Relationship (B ← A)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              _buildRelationshipRow(
                'Hue',
                colorConstraints.relationships
                    .where((r) => r.component == ColorComponent.hue)
                    .toList(),
              ),
              const SizedBox(height: 4),
              _buildRelationshipRow(
                'Sat',
                colorConstraints.relationships
                    .where((r) => r.component == ColorComponent.saturation)
                    .toList(),
              ),
              const SizedBox(height: 4),
              _buildRelationshipRow(
                'Val',
                colorConstraints.relationships
                    .where((r) => r.component == ColorComponent.value)
                    .toList(),
              ),
              const SizedBox(height: 4),
              SizedBox(
                child: OutlinedButton.icon(
                  onPressed: onClearRelationships,
                  label: const Text(
                    'Clear All',
                    style: TextStyle(fontSize: 10, color: Colors.redAccent),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent, width: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRelationshipRow(
    String title,
    List<ColorRelationship> relationships,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: relationships
              .map<Widget>(
                (ColorRelationship relationship) => LinkButton(
                  label: _getRelationshipLabel(relationship),
                  relationship: relationship,
                  onPressed: onRelationshipApplied,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  String _getRelationshipLabel(ColorRelationship relationship) {
    final offsetStr = relationship.offset == 0
        ? ''
        : (relationship.offset > 0
              ? ' + ${relationship.offset.toStringAsFixed(1)}'
              : ' - ${relationship.offset.abs().toStringAsFixed(1)}');

    switch (relationship.component) {
      case ColorComponent.hue:
        return 'Hue ${relationship.operator.symbol}$offsetStr';
      case ColorComponent.saturation:
        return 'Sat ${relationship.operator.symbol}$offsetStr';
      case ColorComponent.value:
        return 'Val ${relationship.operator.symbol}$offsetStr';
    }
  }
}
