import 'dart:ui';

import '../../controllers/canvas_controller.dart';
import '../../models/shape_data.dart';
import '../canvas_command.dart';

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