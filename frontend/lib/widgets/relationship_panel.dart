import 'package:flutter/material.dart';
import 'package:frontend/models/color_component.dart';
import 'package:frontend/models/color_constraints.dart';
import 'package:frontend/models/color_relationship.dart';
import 'package:frontend/widgets/link_button.dart';

class RelationshipPanel extends StatelessWidget {
  final ColorConstraints colorConstraints;
  final ValueChanged<ColorRelationship> onRelationshipApplied;

  const RelationshipPanel({
    super.key,
    required this.colorConstraints,
    required this.onRelationshipApplied,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      right: 20,
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
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: relationships
              .map<Widget>(
                (ColorRelationship relationship) => Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: LinkButton(
                    label: _getRelationshipLabel(relationship),
                    relationship: relationship,
                    onPressed: onRelationshipApplied,
                  ),
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
