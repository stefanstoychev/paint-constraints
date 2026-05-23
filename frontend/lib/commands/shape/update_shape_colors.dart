
import 'package:flutter/material.dart';

import '../../controllers/canvas_controller.dart';
import '../../models/shape_data.dart';
import '../canvas_command.dart';

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