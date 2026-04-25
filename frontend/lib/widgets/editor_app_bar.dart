import 'package:flutter/material.dart';

class EditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showRelationships;
  final bool showColorLabels;
  final bool hasSelectedShapes;
  final bool canUndo;
  final bool canRedo;
  final String projectName;
  final String solverUrl;

  final VoidCallback onToggleShowRelationships;
  final VoidCallback onToggleShowColorLabels;
  final VoidCallback onSendToFront;
  final VoidCallback onPushToBack;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onAddShape;
  final VoidCallback onSave;
  final VoidCallback onLoad;
  final VoidCallback onSolve;
  final ValueChanged<String> onUpdateSolverUrl;

  const EditorAppBar({
    super.key,
    required this.showRelationships,
    required this.showColorLabels,
    required this.hasSelectedShapes,
    required this.canUndo,
    required this.canRedo,
    required this.onToggleShowRelationships,
    required this.onToggleShowColorLabels,
    required this.onSendToFront,
    required this.onPushToBack,
    required this.onUndo,
    required this.onRedo,
    required this.onAddShape,
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
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            projectName,
            style: const TextStyle(fontSize: 14, color: Colors.black),
          ),
          const Text('Shape Operations', style: TextStyle(fontSize: 18)),
        ],
      ),
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: onAddShape,
          tooltip: 'Add New Shape',
        ),
        IconButton(
          icon: const Icon(Icons.auto_awesome),
          onPressed: onSolve,
          tooltip: 'Solve Constraints',
          color: Colors.amber,
        ),
        IconButton(
          icon: const Icon(Icons.undo),
          onPressed: canUndo ? onUndo : null,
          tooltip: 'Undo',
        ),
        IconButton(
          icon: const Icon(Icons.redo),
          onPressed: canRedo ? onRedo : null,
          tooltip: 'Redo',
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'visibility':
                onToggleShowRelationships();
                break;
              case 'colors':
                onToggleShowColorLabels();
                break;
              case 'front':
                onSendToFront();
                break;
              case 'back':
                onPushToBack();
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
                  showRelationships ? Icons.visibility : Icons.visibility_off,
                ),
                title: Text(
                  showRelationships
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
              enabled: hasSelectedShapes,
              child: const ListTile(
                leading: Icon(Icons.vertical_align_top),
                title: Text('Send to Front'),
              ),
            ),
            PopupMenuItem<String>(
              value: 'back',
              enabled: hasSelectedShapes,
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
