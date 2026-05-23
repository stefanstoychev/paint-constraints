import 'dart:ui';

import '../../controllers/canvas_controller.dart';
import '../../models/shape_data.dart';
import '../canvas_command.dart';

class MoveVertexCommand implements CanvasCommand {
  final CanvasController controller;
  final int shapeIndex;
  final int vertexIndex;
  final Offset initialPosition;
  final Offset finalPosition;
  final int? previousSelectedVertexIndex;

  MoveVertexCommand(
      this.controller,
      this.shapeIndex,
      this.vertexIndex,
      this.initialPosition,
      this.finalPosition,
      ) : previousSelectedVertexIndex = controller.selectedVertexIndex;

  @override
  void execute() {
    final shapes = List<ShapeData>.from(controller.allShapes);
    if (shapeIndex < shapes.length) {
      final points = List<Offset>.from(shapes[shapeIndex].points);
      if (vertexIndex < points.length) {
        points[vertexIndex] = finalPosition;
        shapes[shapeIndex] = shapes[shapeIndex].copyWith(points: points);
        controller.allShapes = shapes;
      }
    }
    controller.selectedVertexIndex = vertexIndex;
  }

  @override
  void undo() {
    final shapes = List<ShapeData>.from(controller.allShapes);
    if (shapeIndex < shapes.length) {
      final points = List<Offset>.from(shapes[shapeIndex].points);
      if (vertexIndex < points.length) {
        points[vertexIndex] = initialPosition;
        shapes[shapeIndex] = shapes[shapeIndex].copyWith(points: points);
        controller.allShapes = shapes;
      }
    }
    controller.selectedVertexIndex = previousSelectedVertexIndex;
  }
}