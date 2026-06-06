import 'package:flutter/material.dart';
import 'package:frontend/commands/color_commands.dart';
import 'package:frontend/commands/shape_commands.dart';
import 'package:frontend/controllers/canvas_controller.dart';
import 'package:frontend/models/color_constraint_models.dart';
import 'package:frontend/models/shape_data.dart';
import 'package:frontend/services/solver_service.dart';

class ConstraintManager extends ChangeNotifier {
  void notify() => notifyListeners();

  List<ShapeRelationship> activeRelationships = <ShapeRelationship>[];
  Set<ShapeColorConstraint> activeShapeColorConstraint =
      <ShapeColorConstraint>{};

  void loadConstraints(
    List<ShapeRelationship> relationships,
    Set<ShapeColorConstraint> constraints,
  ) {
    activeRelationships = List.from(relationships);
    activeShapeColorConstraint = Set.from(constraints);
    notifyListeners();
  }

  void clear() {
    activeRelationships.clear();
    activeShapeColorConstraint.clear();
    notifyListeners();
  }

  Future<void> solveRelationships(
    BuildContext context, {
    required SolverService? solverService,
    required List<ShapeData> allShapes,
    required CanvasController controller,
  }) async {
    if (activeRelationships.isEmpty) return;

    final results = await solverService?.solve(
      activeRelationships,
      activeShapeColorConstraint,
    );

    if (results != null) {
      final Map<int, HSVColor> oldColors = {};
      final Map<int, HSVColor> newColors = {};

      for (final result in results) {
        if (result.index >= 0 && result.index < allShapes.length) {
          oldColors[result.index] = allShapes[result.index].hsv;
          newColors[result.index] = HSVColor.fromAHSV(
            1.0,
            result.h,
            result.s / 100,
            result.v / 100,
          );
        }
      }

      if (newColors.isNotEmpty) {
        controller.executeCommand(
          UpdateShapeColorsCommand(controller, oldColors, newColors),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to solve constraints')),
        );
      }
    }
  }

  void applyRelationship({
    required int sourceIdx,
    required int targetIdx,
    required ColorRelationship relationship,
    required BuildContext context,
    required CanvasController controller,
  }) {
    final bool hasReverseRelationship = activeRelationships.any(
      (ShapeRelationship r) =>
          r.sourceShapeIndex == targetIdx &&
          r.targetShapeIndex == sourceIdx &&
          r.relationship.component == relationship.component,
    );
    if (hasReverseRelationship) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reverse relationship already exists')),
        );
      }
      return;
    }

    final shapeRelationship = ShapeRelationship(
      sourceIdx,
      targetIdx,
      relationship,
    );
    final int existingRelationshipIndex = activeRelationships.indexWhere(
      (ShapeRelationship activeRelationship) =>
          activeRelationship.hasSameType(shapeRelationship),
    );

    ShapeRelationship? prevRelationship;
    if (existingRelationshipIndex != -1) {
      prevRelationship = activeRelationships[existingRelationshipIndex];
    }

    controller.executeCommand(
      ApplyRelationshipCommand(
        controller: controller,
        newRelationship: shapeRelationship,
        previousRelationship: prevRelationship,
      ),
    );
  }

  void clearSelectedRelationships({
    required int shapeIndex1,
    required int shapeIndex2,
    required CanvasController controller,
  }) {
    controller.executeCommand(
      RemoveRelationshipsCommand(
        controller: controller,
        shapeIndex1: shapeIndex1,
        shapeIndex2: shapeIndex2,
      ),
    );
  }

  void applyClamp({
    required int shapeIndex,
    required int startH,
    required int endH,
    required int startS,
    required int endS,
    required int startV,
    required int endV,
    required CanvasController controller,
  }) {
    final oldConstraints = {
      ...activeShapeColorConstraint.where(
        (x) => x.sourceShapeIndex == shapeIndex,
      ),
    };
    final newConstraints = {
      ShapeColorConstraint(shapeIndex, ColorComponent.hue, startH, endH),
      ShapeColorConstraint(shapeIndex, ColorComponent.saturation, startS, endS),
      ShapeColorConstraint(shapeIndex, ColorComponent.value, startV, endV),
    };

    controller.executeCommand(
      ApplyColorClampCommand(controller, oldConstraints, newConstraints),
    );
  }
}
