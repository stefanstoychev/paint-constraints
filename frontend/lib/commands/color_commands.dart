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
    controller.constraints.activeShapeColorConstraint.removeAll(oldConstraints);
    controller.constraints.activeShapeColorConstraint.addAll(newConstraints);
    controller.constraints.notify();
  }

  @override
  void undo() {
    controller.constraints.activeShapeColorConstraint.removeAll(newConstraints);
    controller.constraints.activeShapeColorConstraint.addAll(oldConstraints);
    controller.constraints.notify();
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
    final existingRelationshipIndex = controller.constraints.activeRelationships
        .indexWhere((r) => r.hasSameType(newRelationship));

    if (existingRelationshipIndex != -1) {
      controller.constraints.activeRelationships[existingRelationshipIndex] =
          newRelationship;
    } else {
      controller.constraints.activeRelationships.add(newRelationship);
    }
    controller.constraints.notify();
  }

  @override
  void undo() {
    // Restore relationship only
    final existingRelationshipIndex = controller.constraints.activeRelationships
        .indexWhere((r) => r.hasSameType(newRelationship));

    if (existingRelationshipIndex != -1) {
      if (previousRelationship != null) {
        controller.constraints.activeRelationships[existingRelationshipIndex] =
            previousRelationship!;
      } else {
        controller.constraints.activeRelationships.removeAt(
          existingRelationshipIndex,
        );
      }
    }
    controller.constraints.notify();
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
    for (final r in controller.constraints.activeRelationships) {
      if ((r.sourceShapeIndex == shapeIndex1 &&
              r.targetShapeIndex == shapeIndex2) ||
          (r.sourceShapeIndex == shapeIndex2 &&
              r.targetShapeIndex == shapeIndex1)) {
        removedRelationships.add(r);
      } else {
        toKeep.add(r);
      }
    }
    controller.constraints.activeRelationships = toKeep;
    controller.constraints.notify();
  }

  @override
  void undo() {
    controller.constraints.activeRelationships.addAll(removedRelationships);
    controller.constraints.notify();
  }
}
