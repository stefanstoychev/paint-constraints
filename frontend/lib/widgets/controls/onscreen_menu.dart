import 'package:flutter/material.dart';
import 'package:frontend/controllers/canvas_controller.dart';
import 'package:provider/provider.dart';

import 'onscreen_menu_button.dart';
import 'onscreen_menu_letter_button.dart';

class OnscreenMenu extends StatelessWidget {
  const OnscreenMenu({super.key});

  @override
  Widget build(BuildContext context) {
    CanvasController controller = context.watch<CanvasController>();
    return Card(
      elevation: 4,
      color: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OnScreenMenuButton(
              icon: Icons.link,
              isActive: controller.isLinkMode,
              activeColor: Colors.greenAccent,
              onPressed: controller.toggleLinkMode,
              tooltip: 'Link Mode',
            ),
            if (controller.isLinkMode) ...[
              const Divider(color: Colors.white24, height: 16),
              OnscreenMenuButtonLetter(
                letter: "H",
                isActive: controller.isHueVisible,
                activeColor: Colors.lightBlue,
                onPressed: controller.toggleHueVisible,
                tooltip: 'Toggle hue',
                disabledColor: Colors.white24,
              ),
              OnscreenMenuButtonLetter(
                letter: "S",
                isActive: controller.isSatVisible,
                activeColor: Colors.lightBlue,
                onPressed: controller.onToggleSatVisible,
                tooltip: 'Toggle saturation',
                disabledColor: Colors.white24,
              ),
              OnscreenMenuButtonLetter(
                letter: "V",
                isActive: controller.isValueVisible,
                activeColor: Colors.lightBlue,
                onPressed: controller.onToggleValueVisible,
                tooltip: 'Toggle value',
                disabledColor: Colors.white24,
              ),
            ],
            OnScreenMenuButton(
              icon: Icons.ten_k,
              isActive: controller.isClampMode,
              activeColor: Colors.deepPurple,
              onPressed: controller.toggleClampMode,
              tooltip: 'Clamp Mode',
            ),
            const SizedBox(height: 8),
            OnScreenMenuButton(
              icon: Icons.scatter_plot,
              isActive: controller.isEditVerticesMode,
              activeColor: Colors.blueAccent,
              onPressed: controller.toggleEditVerticesMode,
              tooltip: 'Edit Vertices',
            ),
            if (controller.isEditVerticesMode) ...[
              const Divider(color: Colors.white24, height: 16),
              OnScreenMenuButton(
                icon: Icons.delete_outline,
                isActive: controller.hasSelected,
                activeColor: Colors.redAccent,
                onPressed: controller.hasSelected
                    ? controller.deleteSelectedVertex
                    : null,
                tooltip: 'Delete Selected Vertex',
                disabledColor: Colors.white24,
              ),
            ],
            OnScreenMenuButton(
              icon: Icons.redo,
              isActive: controller.canRedo,
              activeColor: Colors.blueGrey,
              onPressed: controller.canRedo ? controller.redo : null,
              tooltip: 'Redo',
              disabledColor: Colors.white24,
            ),
            OnScreenMenuButton(
              icon: Icons.undo,
              isActive: controller.canUndo,
              activeColor: Colors.grey,
              onPressed: controller.canUndo ? controller.undo : null,
              tooltip: 'Undo',
              disabledColor: Colors.white24,
            ),
          ],
        ),
      ),
    );
  }
}
