import 'dart:ui';

import '../controllers/canvas_controller.dart';
import '../models/point_constraint_models.dart';
import '../models/shape_data.dart';
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
      controller.constraints.shiftLinksOnInsert(shapeIndex, vertexIndex);
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
        controller.constraints.unshiftLinksOnInsert(shapeIndex, vertexIndex);
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
  List<VertexLink> _removedLinks = const [];

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
        _removedLinks = controller.constraints.removeLinksOnDelete(
          shapeIndex,
          vertexIndex,
        );
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
      controller.constraints.restoreLinksOnDelete(
        shapeIndex,
        vertexIndex,
        _removedLinks,
      );
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
