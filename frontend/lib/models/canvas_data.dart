import 'package:frontend/models/shape_data.dart';

class CanvasData {
  final List<ShapeData> shapes;
  final List<ShapeRelationship> relationships;

  CanvasData({
    required this.shapes,
    required this.relationships,
  });
}