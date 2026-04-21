import 'package:flutter/material.dart';

class EditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isEditVerticesMode;
  final bool isLinkMode;
  final bool showRelationships;
  final bool showColorLabels;
  final bool hasSelectedVertex;
  final bool hasSelectedShapes;
  final bool canUndo;
  final bool canRedo;
  final String projectName;
  final String solverUrl;

  final VoidCallback onToggleLinkMode;
  final VoidCallback onToggleEditVerticesMode;
  final VoidCallback onDeleteVertex;
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
    required this.isEditVerticesMode,
    required this.isLinkMode,
    required this.showRelationships,
    required this.showColorLabels,
    required this.hasSelectedVertex,
    required this.hasSelectedShapes,
    required this.canUndo,
    required this.canRedo,
    required this.onToggleLinkMode,
    required this.onToggleEditVerticesMode,
    required this.onDeleteVertex,
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
    final bool isSmallScreen = MediaQuery.of(context).size.width < 700;

    return AppBar(
      title: !isSmallScreen
          ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(projectName, style: const TextStyle(fontSize: 14, color: Colors.black)),
              Text(
                isEditVerticesMode
                    ? 'Edit Vertices Mode'
                    : isLinkMode
                    ? 'Select 2 Shapes to Link'
                    : 'Shape Operations',
                style: const TextStyle(fontSize: 18),
              ),
            ],
          )
          : Text(projectName),
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
        if (isSmallScreen)
          _buildIconButton(
            icon: Icons.link,
            isActive: isLinkMode,
            activeColor: Colors.green,
            onPressed: onToggleLinkMode,
            tooltip: 'Link Mode',
          )
        else
          _buildModeButton(
            label: 'Link Mode',
            icon: Icons.link,
            isActive: isLinkMode,
            activeColor: Colors.green,
            onPressed: onToggleLinkMode,
          ),
        if (isSmallScreen)
          _buildIconButton(
            icon: Icons.scatter_plot,
            isActive: isEditVerticesMode,
            activeColor: Colors.blue,
            onPressed: onToggleEditVerticesMode,
            tooltip: 'Edit Vertices',
          )
        else
          _buildModeButton(
            label: 'Edit Vertices',
            icon: Icons.scatter_plot,
            isActive: isEditVerticesMode,
            activeColor: Colors.blue,
            onPressed: onToggleEditVerticesMode,
          ),
        if (isEditVerticesMode)
          IconButton(
            icon: const Icon(Icons.delete),
            color: hasSelectedVertex ? Colors.white : Colors.white38,
            onPressed: hasSelectedVertex ? onDeleteVertex : null,
            tooltip: 'Delete selected vertex',
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
                leading: Icon(
                  showColorLabels ? Icons.label : Icons.label_off,
                ),
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
    final TextEditingController controller =
        TextEditingController(text: solverUrl);
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
                hintText: 'http://localhost:8080',
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

  Widget _buildIconButton({
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: isActive ? activeColor : Colors.grey),
      tooltip: tooltip,
    );
  }

  Widget _buildModeButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: isActive ? activeColor : Colors.grey),
      label: Text(
        label,
        style: TextStyle(color: isActive ? activeColor : Colors.grey),
      ),
    );
  }
}
