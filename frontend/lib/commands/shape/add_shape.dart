import '../../controllers/canvas_controller.dart';
import '../../models/shape_data.dart';
import '../canvas_command.dart';

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