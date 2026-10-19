import 'dart:math';

import 'package:flutter/material.dart';

import '../controllers/canvas_controller.dart';
import '../models/point_constraint_models.dart';
import '../models/shape_data.dart';
import 'canvas_command.dart';

class AddShapeCommand implements CanvasCommand {
  final CanvasController controller;
  final ShapeData shape;
  final int index;
  final List<int> previousSelectedIndices;
  final int? previousSelectedVertexIndex;

  AddShapeCommand(this.controller, this.shape)
    : index = controller.allShapes.length,
      previousSelectedIndices = List.from(controller.selectedIndices),
      previousSelectedVertexIndex = controller.selectedVertexIndex;

  @override
  void execute() {
    controller.allShapes = [...controller.allShapes, shape];
    controller.selectedIndices = [index];
    controller.selectedVertexIndex = null;
  }

  @override
  void undo() {
    final shapes = List<ShapeData>.from(controller.allShapes);
    if (shapes.isNotEmpty) shapes.removeLast();
    controller.allShapes = shapes;
    controller.selectedIndices = previousSelectedIndices;
    controller.selectedVertexIndex = previousSelectedVertexIndex;
  }
}

class MoveShapeCommand implements CanvasCommand {
  final CanvasController controller;
  final Map<int, List<Offset>> initialPoints;
  final Map<int, List<Offset>> finalPoints;

  MoveShapeCommand(this.controller, this.initialPoints, this.finalPoints);

  @override
  void execute() {
    final shapes = List<ShapeData>.from(controller.allShapes);
    for (final entry in finalPoints.entries) {
      if (entry.key < shapes.length) {
        shapes[entry.key] = shapes[entry.key].copyWith(points: entry.value);
      }
    }
    controller.allShapes = shapes;
  }

  @override
  void undo() {
    final shapes = List<ShapeData>.from(controller.allShapes);
    for (final entry in initialPoints.entries) {
      if (entry.key < shapes.length) {
        shapes[entry.key] = shapes[entry.key].copyWith(points: entry.value);
      }
    }
    controller.allShapes = shapes;
  }
}

/// Cuts a shape along the chord between two of its vertices. The first part
/// keeps the shape's index (and so its color constraints); the second part is
/// appended as a new shape.
class SplitShapeCommand implements CanvasCommand {
  final CanvasController controller;
  final int shapeIndex;
  final int newShapeIndex;
  final ShapeData originalShape;
  late final ShapeData firstPart;
  late final ShapeData secondPart;
  final List<VertexLink> previousLinks;
  late final List<VertexLink> splitLinks;

  SplitShapeCommand(this.controller, this.shapeIndex, int i, int j)
    : newShapeIndex = controller.allShapes.length,
      originalShape = controller.allShapes[shapeIndex],
      previousLinks = List.of(controller.constraints.activeVertexLinks) {
    final List<Offset> points = originalShape.points;
    final int n = points.length;
    final int a = min(i, j);
    final int b = max(i, j);

    firstPart = originalShape.copyWith(points: points.sublist(a, b + 1));
    secondPart = originalShape.copyWith(
      points: [...points.sublist(b), ...points.sublist(0, a + 1)],
    );

    // Vertices a..b go to the first part; the rest to the second. The cut
    // vertices exist in both, and their links stay with the first part.
    VertexRef remap(VertexRef v) {
      if (v.shapeIndex != shapeIndex) return v;
      final int k = v.vertexIndex;
      if (k >= a && k <= b) return VertexRef(shapeIndex, k - a);
      if (k > b) return VertexRef(newShapeIndex, k - b);
      return VertexRef(newShapeIndex, k + n - b);
    }

    splitLinks = previousLinks
        .map((l) => VertexLink(remap(l.a), remap(l.b)))
        .toList();
  }

  @override
  void execute() {
    final shapes = List<ShapeData>.from(controller.allShapes);
    shapes[shapeIndex] = firstPart;
    shapes.add(secondPart);
    controller.allShapes = shapes;
    controller.constraints.activeVertexLinks = List.of(splitLinks);
  }

  @override
  void undo() {
    final shapes = List<ShapeData>.from(controller.allShapes);
    if (shapes.length > newShapeIndex) shapes.removeAt(newShapeIndex);
    shapes[shapeIndex] = originalShape;
    controller.allShapes = shapes;
    controller.constraints.activeVertexLinks = List.of(previousLinks);
    controller.selectedIndices = controller.selectedIndices
        .where((index) => index < shapes.length)
        .toList();
  }
}

class ReorderShapesCommand implements CanvasCommand {
  final CanvasController controller;
  final List<ShapeData> previousShapes;
  final List<ShapeData> newShapes;

  ReorderShapesCommand(this.controller, this.previousShapes, this.newShapes);

  @override
  void execute() {
    controller.allShapes = newShapes;
  }

  @override
  void undo() {
    controller.allShapes = previousShapes;
  }
}

class UpdateShapeColorsCommand implements CanvasCommand {
  final CanvasController controller;
  final Map<int, HSVColor> oldColors;
  final Map<int, HSVColor> newColors;

  UpdateShapeColorsCommand(this.controller, this.oldColors, this.newColors);

  @override
  void execute() {
    final shapes = List<ShapeData>.from(controller.allShapes);
    for (final entry in newColors.entries) {
      if (entry.key < shapes.length) {
        shapes[entry.key] = shapes[entry.key].copyWith(hsv: entry.value);
      }
    }
    controller.allShapes = shapes;
  }

  @override
  void undo() {
    final shapes = List<ShapeData>.from(controller.allShapes);
    for (final entry in oldColors.entries) {
      if (entry.key < shapes.length) {
        shapes[entry.key] = shapes[entry.key].copyWith(hsv: entry.value);
      }
    }
    controller.allShapes = shapes;
  }
}
