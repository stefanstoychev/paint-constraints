import 'package:frontend/models/color_constraint_models.dart';
import 'package:frontend/models/point_constraint_models.dart';
import 'package:frontend/models/shape_data.dart';

enum EditMode {
  linkShapesColor,
  editShapeVertexes,
  linkVertexes,
  clampColor,
  selectShape,
}

class CanvasData {
  final List<ShapeData> shapes;
  final List<ShapeRelationship> relationships;
  final Set<ShapeColorConstraint> constraints;
  final List<VertexLink> vertexLinks;

  CanvasData({
    required this.shapes,
    required this.relationships,
    required this.constraints,
    this.vertexLinks = const [],
  });

  factory CanvasData.fromJson(Map<String, dynamic> json) {
    return CanvasData(
      shapes: (json['shapes'] as List)
          .map((s) => ShapeData.fromJson(s as Map<String, dynamic>))
          .toList(),
      relationships: (json['relationships'] as List)
          .map((r) => ShapeRelationship.fromJson(r as Map<String, dynamic>))
          .toList(),
      constraints: (json['constraints'] as List)
          .map((r) => ShapeColorConstraint.fromJson(r as Map<String, dynamic>))
          .toSet(),
      vertexLinks: ((json['vertexLinks'] as List?) ?? const [])
          .map((l) => VertexLink.fromJson(l as Map<String, dynamic>))
          .toList(),
    );
  }
}
