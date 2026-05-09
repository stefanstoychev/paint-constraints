import 'package:frontend/models/shape_color_clamp.dart';
import 'package:frontend/models/shape_data.dart';
import 'package:frontend/models/shape_relationship.dart';

class CanvasData {
  final List<ShapeData> shapes;
  final List<ShapeRelationship> relationships;
  final Set<ShapeColorConstraint> constraints;

  CanvasData({required this.shapes, required this.relationships, required this.constraints});

  factory CanvasData.fromJson(Map<String, dynamic> json) {
    return CanvasData(
      shapes: (json['shapes'] as List)
          .map((s) => ShapeData.fromJson(s as Map<String, dynamic>))
          .toList(),
      relationships: (json['relationships'] as List)
          .map((r) => ShapeRelationship.fromJson(r as Map<String, dynamic>))
          .toList(),
      constraints: (json['constraints'] as Set)
        .map((r) => ShapeColorConstraint.fromJson(r as Map<String, dynamic>))
        .toSet(),
    );
  }
}
