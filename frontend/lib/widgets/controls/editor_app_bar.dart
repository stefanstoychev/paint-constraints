import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/canvas_controller.dart';

class EditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showColorLabels;
  final String projectName;
  final String solverUrl;

  final VoidCallback onToggleShowRelationships;
  final VoidCallback onSave;
  final VoidCallback onLoad;
  final VoidCallback onSolve;
  final ValueChanged<String> onUpdateSolverUrl;

  const EditorAppBar({
    super.key,
    required this.showColorLabels,
    required this.onToggleShowRelationships,
    required this.onSave,
    required this.onLoad,
    required this.onSolve,
    required this.onUpdateSolverUrl,
    required this.projectName,
    required this.solverUrl,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    CanvasController controller = context.watch<CanvasController>();
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            projectName,
            style: const TextStyle(fontSize: 14, color: Colors.black),
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
              enabled: controller.hasSelected,
              child: const ListTile(
                leading: Icon(Icons.vertical_align_top),
                title: Text('Send to Front'),
              ),
            ),
            PopupMenuItem<String>(
              value: 'back',
              enabled: controller.hasSelected,
              child: const ListTile(
                leading: Icon(Icons.vertical_align_bottom),
                title: Text('Push to Back'),
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'save',
              child: ListTile(
                leading: Icon(Icons.save),
                title: Text('Save Project'),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'load',
              child: ListTile(
                leading: Icon(Icons.folder_open),
                title: Text('Load Project'),
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
      text: solverUrl,
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
              onUpdateSolverUrl(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
