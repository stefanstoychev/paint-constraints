import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/controllers/canvas_controller.dart';
import 'package:frontend/main.dart' as app;
import 'package:frontend/widgets/canvas_grid.dart';
import 'package:frontend/widgets/controls/onscreen_menu.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Paint Constraints - UI flow', () {
    testWidgets('01 gallery (empty state)', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('No paintings yet'), findsOneWidget);
      await binding.takeScreenshot('01_gallery_empty');
    });

    testWidgets('02 create project and enter editor', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Open create dialog
      await tester.tap(find.text('New Painting'));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('02_create_dialog');

      expect(find.text('New Canvas'), findsOneWidget);

      // Type a name
      await tester.enterText(
        find.widgetWithText(TextField, 'My Masterpiece'),
        'Integration Test Canvas',
      );
      await tester.pumpAndSettle();
      await binding.takeScreenshot('03_create_dialog_filled');

      // Confirm create
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await binding.takeScreenshot('04_canvas_empty');

      // Should now be in the editor
      expect(find.byTooltip('Add New Shape'), findsOneWidget);
    });

    testWidgets('03 add shapes and use toolbar', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Create project
      await tester.tap(find.text('New Painting'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'My Masterpiece'),
        'Toolbar Test',
      );
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Add first shape
      await tester.tap(find.byTooltip('Add New Shape'));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('05_one_shape');

      // Add second shape
      await tester.tap(find.byTooltip('Add New Shape'));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('06_two_shapes');

      // Enter link mode
      await tester.tap(find.byTooltip('Relate Colors'));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('07_link_mode_active');

      // Exit link mode
      await tester.tap(find.byTooltip('Relate Colors'));
      await tester.pumpAndSettle();

      // Enter edit vertices mode
      await tester.tap(find.byTooltip('Edit Vertices'));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('08_edit_vertices_mode');

      // Exit edit vertices mode
      await tester.tap(find.byTooltip('Edit Vertices'));
      await tester.pumpAndSettle();

      // Undo last add-shape
      await tester.tap(find.byTooltip('Undo'));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('09_after_undo');

      // Redo
      await tester.tap(find.byTooltip('Redo'));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('10_after_redo');
    });

    testWidgets('04 clamp mode with shape selected', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Create project
      await tester.tap(find.text('New Painting'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'My Masterpiece'),
        'Clamp Test',
      );
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Add a shape
      await tester.tap(find.byTooltip('Add New Shape'));
      await tester.pumpAndSettle();

      // Enter clamp mode
      await tester.tap(find.byTooltip('Limit Color Range'));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('11_clamp_mode_no_selection');

      // The canvas rect is Rect.fromLTWH(20, 20, 460, 320).
      // fitToScreen scales it to fill the viewport; the first shape's centroid
      // is at world (150, 150). Replicate the viewport transform to find the
      // screen tap point.
      final view = tester.view;
      final logicalW = view.physicalSize.width / view.devicePixelRatio;
      final logicalH = view.physicalSize.height / view.devicePixelRatio;
      const kToolbar = 56.0;
      const canvasW = 460.0, canvasH = 320.0;
      const canvasLeft = 20.0, canvasTop = 20.0;
      final availH = logicalH - kToolbar;
      final scale = (availH / canvasH) < (logicalW / canvasW)
          ? availH / canvasH
          : logicalW / canvasW;
      final offsetX = (logicalW - canvasW * scale) / 2 - canvasLeft * scale;
      final offsetY = (availH - canvasH * scale) / 2 - canvasTop * scale;
      // Shape centroid in world coords: (150, 150)
      final shapeTapX = 150.0 * scale + offsetX;
      final shapeTapY = 150.0 * scale + offsetY + kToolbar;
      await tester.tapAt(Offset(shapeTapX, shapeTapY));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('12_clamp_panel_open');
    });

    testWidgets('05 link mode with two shapes selected', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Create project
      await tester.tap(find.text('New Painting'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'My Masterpiece'),
        'Link Test',
      );
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Add two shapes
      await tester.tap(find.byTooltip('Add New Shape'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Add New Shape'));
      await tester.pumpAndSettle();

      // Enter link mode
      await tester.tap(find.byTooltip('Relate Colors'));
      await tester.pumpAndSettle();

      // Tap two different locations to select both shapes
      final size = tester.view.physicalSize / tester.view.devicePixelRatio;
      final cx = size.width / 2;
      final cy = size.height / 2;
      await tester.tapAt(Offset(cx - 60, cy));
      await tester.pumpAndSettle();
      await tester.tapAt(Offset(cx + 60, cy));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('13_link_mode_two_selected');
    });

    testWidgets('06 save project and return to gallery', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Create project
      await tester.tap(find.text('New Painting'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'My Masterpiece'),
        'Save Test',
      );
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Add a shape
      await tester.tap(find.byTooltip('Add New Shape'));
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.byTooltip('Save Project'));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('14_after_save');

      // Back to gallery
      final backButton = find.byTooltip('Back');
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
      } else {
        // AppBar back button on web uses a leading icon
        await tester.tap(find.byType(BackButton));
      }
      await tester.pumpAndSettle();
      await binding.takeScreenshot('15_gallery_with_project');

      expect(find.text('Save Test'), findsOneWidget);
    });

    testWidgets('07 snap vertices together', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Create project
      await tester.tap(find.text('New Painting'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'My Masterpiece'),
        'Snap Test',
      );
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Add two overlapping squares:
      // shape 0 = (100,100)-(200,200), shape 1 = (120,120)-(220,220).
      await tester.tap(find.byTooltip('Add New Shape'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Add New Shape'));
      await tester.pumpAndSettle();

      final controller = Provider.of<CanvasController>(
        tester.element(find.byType(OnscreenMenu)),
        listen: false,
      );
      final canvasOrigin = tester.getTopLeft(find.byType(CanvasGrid));
      Offset toScreen(Offset world) =>
          canvasOrigin +
          world * controller.viewport.currentScale +
          controller.viewport.currentOffset;

      // Snap mode: tap shape 0's top-right corner, then shape 1's top-left.
      await tester.tap(find.byTooltip('Snap Vertices Together'));
      await tester.pumpAndSettle();
      await tester.tapAt(toScreen(controller.allShapes[0].points[1]));
      await tester.pumpAndSettle();
      await tester.tapAt(toScreen(controller.allShapes[1].points[0]));
      await tester.pumpAndSettle();

      expect(controller.constraints.activeVertexLinks, hasLength(1));
      expect(
        controller.allShapes[1].points[0],
        controller.allShapes[0].points[1],
      );
      await binding.takeScreenshot('16_snap_vertices_linked');

      // Drag the shared corner in edit-vertices mode; both shapes follow.
      await tester.tap(find.byTooltip('Snap Vertices Together'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Edit Vertices'));
      await tester.pumpAndSettle();
      // Select shape 0 by tapping a spot only it covers.
      await tester.tapAt(toScreen(const Offset(110, 110)));
      await tester.pumpAndSettle();

      final corner = controller.allShapes[0].points[1];
      // Mouse pointer so the drag slop stays well inside the handle radius.
      final gesture = await tester.startGesture(
        toScreen(corner),
        kind: PointerDeviceKind.mouse,
      );
      for (int i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(6, -4));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(controller.allShapes[0].points[1], isNot(corner));
      expect(
        controller.allShapes[1].points[0],
        controller.allShapes[0].points[1],
      );
      await binding.takeScreenshot('17_snap_vertices_dragged');

      // Separate them again.
      await tester.tap(find.byTooltip('Edit Vertices'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Snap Vertices Together'));
      await tester.pumpAndSettle();
      await tester.tapAt(toScreen(controller.allShapes[0].points[1]));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Separate Vertices'));
      await tester.pumpAndSettle();

      expect(controller.constraints.activeVertexLinks, isEmpty);
      await binding.takeScreenshot('18_snap_vertices_separated');
    });
  });
}
