import '../../controllers/canvas_controller.dart';
import '../../models/shape_data.dart';
import '../canvas_command.dart';

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