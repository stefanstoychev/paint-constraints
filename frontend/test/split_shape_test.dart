import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/commands/shape_commands.dart';
import 'package:frontend/controllers/canvas_controller.dart';
import 'package:frontend/models/point_constraint_models.dart';
import 'package:frontend/models/shape_data.dart';
import 'package:frontend/utils/geometry_utils.dart';

const HSVColor _color = HSVColor.fromAHSV(1, 120, 0.5, 0.5);

const List<Offset> _square = [
  Offset(100, 100),
  Offset(200, 100),
  Offset(200, 200),
  Offset(100, 200),
];

// Hexagon around (300, 150).
const List<Offset> _hexagon = [
  Offset(280, 100),
  Offset(320, 100),
  Offset(340, 150),
  Offset(320, 200),
  Offset(280, 200),
  Offset(260, 150),
];

// Arrow-shaped concave polygon: the notch at vertex 3 points inwards.
const List<Offset> _concave = [
  Offset(100, 100),
  Offset(200, 100),
  Offset(200, 200),
  Offset(150, 120),
  Offset(100, 200),
];

void main() {
  group('GeometryUtils.isValidDiagonal', () {
    test('accepts opposite corners of a square', () {
      expect(GeometryUtils.isValidDiagonal(_square, 0, 2), isTrue);
      expect(GeometryUtils.isValidDiagonal(_square, 3, 1), isTrue);
    });

    test('rejects neighbours and the same vertex', () {
      expect(GeometryUtils.isValidDiagonal(_square, 0, 1), isFalse);
      expect(GeometryUtils.isValidDiagonal(_square, 0, 3), isFalse);
      expect(GeometryUtils.isValidDiagonal(_square, 2, 2), isFalse);
    });

    test('rejects a cut that leaves a concave shape', () {
      // 2 -> 4 runs across the notch, outside the shape.
      expect(GeometryUtils.isValidDiagonal(_concave, 2, 4), isFalse);
      // 0 -> 3 stays inside.
      expect(GeometryUtils.isValidDiagonal(_concave, 0, 3), isTrue);
    });
  });

  group('SplitShapeCommand', () {
    test('cuts a square into two triangles and undo restores it', () {
      final controller = CanvasController()
        ..allShapes = [const ShapeData(points: _square, hsv: _color)];

      controller.executeCommand(SplitShapeCommand(controller, 0, 0, 2));

      expect(controller.allShapes, hasLength(2));
      expect(controller.allShapes[0].points, [
        _square[0],
        _square[1],
        _square[2],
      ]);
      expect(controller.allShapes[1].points, [
        _square[2],
        _square[3],
        _square[0],
      ]);
      expect(controller.allShapes[1].hsv, _color);

      controller.undo();
      expect(controller.allShapes, hasLength(1));
      expect(controller.allShapes[0].points, _square);

      controller.redo();
      expect(controller.allShapes, hasLength(2));
    });

    test('moves vertex links to the piece that now owns the vertex', () {
      final controller = CanvasController()
        ..allShapes = [
          const ShapeData(points: _hexagon, hsv: _color),
          const ShapeData(points: _square, hsv: _color),
        ];
      const before = [
        VertexLink(VertexRef(0, 5), VertexRef(1, 0)),
        VertexLink(VertexRef(0, 2), VertexRef(1, 1)),
        VertexLink(VertexRef(0, 4), VertexRef(1, 2)),
      ];
      controller.constraints.activeVertexLinks = List.of(before);

      // First part: vertices 1..4. Second part (new shape 2): 4, 5, 0, 1.
      controller.executeCommand(SplitShapeCommand(controller, 0, 4, 1));

      expect(controller.allShapes[0].points, _hexagon.sublist(1, 5));
      expect(controller.allShapes[2].points, [
        _hexagon[4],
        _hexagon[5],
        _hexagon[0],
        _hexagon[1],
      ]);
      expect(controller.constraints.activeVertexLinks, const [
        VertexLink(VertexRef(2, 1), VertexRef(1, 0)),
        VertexLink(VertexRef(0, 1), VertexRef(1, 1)),
        // Cut vertex stays with the first part.
        VertexLink(VertexRef(0, 3), VertexRef(1, 2)),
      ]);

      controller.undo();
      expect(controller.constraints.activeVertexLinks, before);
    });
  });

  group('split shape mode taps', () {
    void tapAt(CanvasController controller, Offset position) {
      controller.handleTapDown(TapDownDetails(localPosition: position));
    }

    test('two opposite corners split the shape', () {
      final controller = CanvasController()
        ..allShapes = [const ShapeData(points: _square, hsv: _color)];
      controller.toggleSplitShapeMode();

      tapAt(controller, _square[1]);
      expect(controller.pendingVertex, const VertexRef(0, 1));
      tapAt(controller, _square[3]);

      expect(controller.allShapes, hasLength(2));
      expect(controller.pendingVertex, isNull);
    });

    test('neighbouring corners do not split, second tap becomes pending', () {
      final controller = CanvasController()
        ..allShapes = [const ShapeData(points: _square, hsv: _color)];
      controller.toggleSplitShapeMode();

      tapAt(controller, _square[0]);
      tapAt(controller, _square[1]);

      expect(controller.allShapes, hasLength(1));
      expect(controller.pendingVertex, const VertexRef(0, 1));
    });

    test('leaving the mode clears the pending vertex', () {
      final controller = CanvasController()
        ..allShapes = [const ShapeData(points: _square, hsv: _color)];
      controller.toggleSplitShapeMode();
      tapAt(controller, _square[0]);

      controller.toggleEditVerticesMode();
      expect(controller.pendingVertex, isNull);
    });
  });
}
