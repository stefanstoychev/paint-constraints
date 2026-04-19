import 'package:frontend/models/shape_data.dart';

class CanvasData {
  final List<ShapeData> shapes;
  final List<ShapeRelationship> relationships;

  CanvasData({required this.shapes, required this.relationships});

  factory CanvasData.fromJson(Map<String, dynamic> json) {
    return CanvasData(
      shapes: (json['shapes'] as List)
          .map((s) => ShapeData.fromJson(s as Map<String, dynamic>))
          .toList(),
      relationships: (json['relationships'] as List)
          .map((r) => ShapeRelationship.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}
