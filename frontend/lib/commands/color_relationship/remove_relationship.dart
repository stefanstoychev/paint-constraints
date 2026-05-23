
import '../../controllers/canvas_controller.dart';
import '../../models/shape_relationship.dart';
import '../canvas_command.dart';

class RemoveRelationshipsCommand implements CanvasCommand {
  final CanvasController controller;
  final int shapeIndex1;
  final int shapeIndex2;
  final List<ShapeRelationship> removedRelationships;

  RemoveRelationshipsCommand({
    required this.controller,
    required this.shapeIndex1,
    required this.shapeIndex2,
  }) : removedRelationships = [];

  @override
  void execute() {
    removedRelationships.clear();
    final List<ShapeRelationship> toKeep = [];
    for (final r in controller.activeRelationships) {
      if ((r.sourceShapeIndex == shapeIndex1 &&
          r.targetShapeIndex == shapeIndex2) ||
          (r.sourceShapeIndex == shapeIndex2 &&
              r.targetShapeIndex == shapeIndex1)) {
        removedRelationships.add(r);
      } else {
        toKeep.add(r);
      }
    }
    controller.activeRelationships = toKeep;
  }

  @override
  void undo() {
    controller.activeRelationships.addAll(removedRelationships);
  }
}