import '../controllers/canvas_controller.dart';
import '../models/color_constraint_models.dart';
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

class ApplyRelationshipCommand implements CanvasCommand {
  final CanvasController controller;
  final ShapeRelationship newRelationship;

  // Previous state (only relationship)
  final ShapeRelationship? previousRelationship;

  ApplyRelationshipCommand({
    required this.controller,
    required this.newRelationship,
    this.previousRelationship,
  });

  @override
  void execute() {
    // Add or update relationship only
    final existingRelationshipIndex = controller.activeRelationships.indexWhere(
      (r) => r.hasSameType(newRelationship),
    );

    if (existingRelationshipIndex != -1) {
      controller.activeRelationships[existingRelationshipIndex] =
          newRelationship;
    } else {
      controller.activeRelationships.add(newRelationship);
    }
  }

  @override
  void undo() {
    // Restore relationship only
    final existingRelationshipIndex = controller.activeRelationships.indexWhere(
      (r) => r.hasSameType(newRelationship),
    );

    if (existingRelationshipIndex != -1) {
      if (previousRelationship != null) {
        controller.activeRelationships[existingRelationshipIndex] =
            previousRelationship!;
      } else {
        controller.activeRelationships.removeAt(existingRelationshipIndex);
      }
    }
  }
}

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
