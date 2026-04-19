import 'dart:ui';
import 'package:frontend/controllers/canvas_controller.dart';
import 'package:frontend/models/shape_data.dart';
import 'canvas_command.dart';

class AddVertexCommand implements CanvasCommand {
  final CanvasController controller;
  final int shapeIndex;
  final int vertexIndex;
  final Offset position;
  final int? previousSelectedVertexIndex;

  AddVertexCommand(
    this.controller,
    this.shapeIndex,
    this.vertexIndex,
    this.position,
  ) : previousSelectedVertexIndex = controller.selectedVertexIndex;

  @override
  void execute() {
    final shapes = List<ShapeData>.from(controller.allShapes);
    if (shapeIndex < shapes.length) {
      final points = List<Offset>.from(shapes[shapeIndex].points);
      points.insert(vertexIndex, position);
      shapes[shapeIndex] = shapes[shapeIndex].copyWith(points: points);
      controller.allShapes = shapes;
    }
    controller.selectedVertexIndex = null;
  }

  @override
  void undo() {
    final shapes = List<ShapeData>.from(controller.allShapes);
    if (shapeIndex < shapes.length) {
      final points = List<Offset>.from(shapes[shapeIndex].points);
      if (vertexIndex < points.length) {
        points.removeAt(vertexIndex);
        shapes[shapeIndex] = shapes[shapeIndex].copyWith(points: points);
        controller.allShapes = shapes;
      }
    }
    controller.selectedVertexIndex = previousSelectedVertexIndex;
  }
}

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

class DeleteVertexCommand implements CanvasCommand {
  final CanvasController controller;
  final int shapeIndex;
  final int vertexIndex;
  final Offset position;
  final int? previousSelectedVertexIndex;

  DeleteVertexCommand(
    this.controller,
    this.shapeIndex,
    this.vertexIndex,
    this.position,
  ) : previousSelectedVertexIndex = controller.selectedVertexIndex;

  @override
  void execute() {
    final shapes = List<ShapeData>.from(controller.allShapes);
    if (shapeIndex < shapes.length) {
      final points = List<Offset>.from(shapes[shapeIndex].points);
      if (vertexIndex < points.length) {
        points.removeAt(vertexIndex);
        shapes[shapeIndex] = shapes[shapeIndex].copyWith(points: points);
        controller.allShapes = shapes;
      }
    }
    controller.selectedVertexIndex = null;
    controller.draggingPointIndex = null;
    controller.draggingShapeIndex = null;
  }

  @override
  void undo() {
    final shapes = List<ShapeData>.from(controller.allShapes);
    if (shapeIndex < shapes.length) {
      final points = List<Offset>.from(shapes[shapeIndex].points);
      points.insert(vertexIndex, position);
      shapes[shapeIndex] = shapes[shapeIndex].copyWith(points: points);
      controller.allShapes = shapes;
    }
    controller.selectedVertexIndex = previousSelectedVertexIndex;
  }
}
