import 'package:flutter/material.dart';
import 'package:frontend/controllers/canvas_controller.dart';
import 'package:frontend/models/shape_data.dart';
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
