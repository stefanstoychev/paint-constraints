import 'package:flutter/material.dart';
import 'package:frontend/models/color_component.dart';
import 'package:frontend/models/color_constraints.dart';
import 'package:frontend/models/color_relationship.dart';


class RelationshipPanel extends StatelessWidget {
  const RelationshipPanel({
    super.key,
    required this.colorConstraints,
    required this.onRelationshipApplied,
    required this.onClearRelationships,
    this.activeRelationships = const [],
  });

  final ColorConstraints colorConstraints;
  final ValueChanged<ColorRelationship> onRelationshipApplied;
  final VoidCallback onClearRelationships;
  final List<ColorRelationship> activeRelationships;

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Positioned(
      top: isSmallScreen ? 70 : 20,
      right: isSmallScreen ? 10 : 20,
      left: isSmallScreen ? 10 : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Card(
          elevation: 8,
          color: Colors.black.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Define Relationship (A -> B)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                _buildRelationshipRow(
                  'Hue',
                  colorConstraints.relationships
                      .where((r) => r.component == ColorComponent.hue)
                      .toList(),
                ),
                const SizedBox(height: 8),
                _buildRelationshipRow(
                  'Saturation',
                  colorConstraints.relationships
                      .where((r) => r.component == ColorComponent.saturation)
                      .toList(),
                ),
                const SizedBox(height: 8),
                _buildRelationshipRow(
                  'Value',
                  colorConstraints.relationships
                      .where((r) => r.component == ColorComponent.value)
                      .toList(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onClearRelationships,
                    icon: const Icon(
                      Icons.clear_all,
                      size: 14,
                      color: Colors.redAccent,
                    ),
                    label: const Text(
                      'Clear All Relationships',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.redAccent.withValues(alpha: 0.5),
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ColorRelationship>(
            segments: relationships
                .map(
                  (r) => ButtonSegment<ColorRelationship>(
                    value: r,
                    label: Text(
                      _getShortRelationshipLabel(r),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                )
                .toList(),
            selected: activeRelationships
                .where((active) => relationships.contains(active))
                .toSet(),
            onSelectionChanged: (newSelection) {
              if (newSelection.isNotEmpty) {
                onRelationshipApplied(newSelection.first);
              }
            },
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              backgroundColor: Colors.transparent,
              selectedBackgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
              selectedForegroundColor: Colors.blueAccent,
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white24, width: 0.5),
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }

  String _getShortRelationshipLabel(ColorRelationship relationship) {
    final offsetStr = relationship.offset == 0
        ? ''
        : (relationship.offset > 0
            ? ' + ${relationship.offset.toInt()}'
            : ' - ${relationship.offset.abs().toInt()}');

    return '${relationship.operator.symbol}$offsetStr';
  }

}
