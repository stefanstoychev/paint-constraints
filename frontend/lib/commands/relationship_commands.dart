import 'package:flutter/material.dart';
import 'package:frontend/controllers/canvas_controller.dart';
import 'package:frontend/models/shape_data.dart';
import 'canvas_command.dart';

class ApplyRelationshipCommand implements CanvasCommand {
  final CanvasController controller;
  final ShapeRelationship newRelationship;
  final HSVColor newTargetHsv;
  final int targetShapeIndex;

  // Previous state
  final ShapeRelationship? previousRelationship;
  final HSVColor previousTargetHsv;

  ApplyRelationshipCommand({
    required this.controller,
    required this.newRelationship,
    required this.newTargetHsv,
    required this.targetShapeIndex,
    this.previousRelationship,
    required this.previousTargetHsv,
  });

  @override
  void execute() {
    // Add or update relationship
    final existingRelationshipIndex = controller.activeRelationships.indexWhere(
      (r) => r.hasSameType(newRelationship),
    );

    if (existingRelationshipIndex != -1) {
      controller.activeRelationships[existingRelationshipIndex] =
          newRelationship;
    } else {
      controller.activeRelationships.add(newRelationship);
    }

    // Update shape
    final shapes = List<ShapeData>.from(controller.allShapes);
    if (targetShapeIndex < shapes.length) {
      shapes[targetShapeIndex] = shapes[targetShapeIndex].copyWith(
        hsv: newTargetHsv,
      );
      controller.allShapes = shapes;
    }
  }

  @override
  void undo() {
    // Restore relationship
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

    // Restore shape
    final shapes = List<ShapeData>.from(controller.allShapes);
    if (targetShapeIndex < shapes.length) {
      shapes[targetShapeIndex] = shapes[targetShapeIndex].copyWith(
        hsv: previousTargetHsv,
      );
      controller.allShapes = shapes;
    }
  }
}
