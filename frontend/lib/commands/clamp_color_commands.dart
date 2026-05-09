
import 'package:frontend/controllers/canvas_controller.dart';
import 'package:frontend/models/shape_color_clamp.dart';

import 'canvas_command.dart';

class ApplyColorClampCommand implements CanvasCommand {

  final CanvasController controller;

  Set<ShapeColorConstraint> oldConstraints = <ShapeColorConstraint>{};
  Set<ShapeColorConstraint> newConstraints = <ShapeColorConstraint>{};

  ApplyColorClampCommand(
    this.controller,
    this.oldConstraints,
    this.newConstraints,
  );

  @override
  void execute() {
    controller.activeShapeColorConstraint.removeAll(oldConstraints);
    controller.activeShapeColorConstraint.addAll(newConstraints);
  }

  @override
  void undo() {
    controller.activeShapeColorConstraint.removeAll(newConstraints);
    controller.activeShapeColorConstraint.addAll(oldConstraints);
  }

}