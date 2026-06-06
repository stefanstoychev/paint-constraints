import 'package:flutter/material.dart';
import 'package:frontend/services/solver_service.dart';
import 'package:provider/provider.dart';

import '../../controllers/canvas_controller.dart';

class EditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showColorLabels;
  final String projectName;

  final VoidCallback onToggleShowRelationships;
  final VoidCallback onSave;
  final VoidCallback onLoad;
  final VoidCallback onSolve;

  const EditorAppBar({
    super.key,
    required this.showColorLabels,
    required this.onToggleShowRelationships,
    required this.onSave,
    required this.onLoad,
    required this.onSolve,
    required this.projectName,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    CanvasController controller = context.watch<CanvasController>();
    return AppBar(
      titleSpacing: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              projectName,
              style: const TextStyle(fontSize: 14, color: Colors.black),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: onSave,
            tooltip: 'Save Project',
          ),
        ],
      ),
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: controller.addShape,
          tooltip: 'Add New Shape',
        ),
        IconButton(
          icon: const Icon(Icons.calculate),
          onPressed: onSolve,
          tooltip: 'Solve Constraints',
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'visibility':
                controller.toggleShowRelationships();
                break;
              case 'colors':
                controller.toggleShowColorLabels();
                break;
              case 'front':
                controller.sendSelectedShapesToFront();
                break;
              case 'back':
                controller.pushSelectedShapesToBack();
                break;
              case 'save':
                onSave();
                break;
              case 'load':
                onLoad();
                break;
              case 'settings':
                _showSettingsDialog(context);
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'visibility',
              child: ListTile(
                leading: Icon(
                  controller.showRelationships
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                title: Text(
                  controller.showRelationships
                      ? 'Hide Relationships'
                      : 'Show Relationships',
                ),
              ),
            ),
            PopupMenuItem<String>(
              value: 'colors',
              child: ListTile(
                leading: Icon(showColorLabels ? Icons.label : Icons.label_off),
                title: Text(
                  showColorLabels ? 'Hide Color Labels' : 'Show Color Labels',
                ),
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'front',
              enabled: controller.selectedIndices.isNotEmpty,
              child: const ListTile(
                leading: Icon(Icons.vertical_align_top),
                title: Text('Send to Front'),
              ),
            ),
            PopupMenuItem<String>(
              value: 'back',
              enabled: controller.selectedIndices.isNotEmpty,
              child: const ListTile(
                leading: Icon(Icons.vertical_align_bottom),
                title: Text('Push to Back'),
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text('Solver Settings'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showSettingsDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController(
      text: context.read<SolverService>().getUrl(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solver Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Solver Server URL',
                hintText: 'https://paint-constraints-api.devfriday.top',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<SolverService>().setUrl(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
