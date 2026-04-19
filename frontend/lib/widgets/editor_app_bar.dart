import 'package:flutter/material.dart';

class EditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isEditVerticesMode;
  final bool isLinkMode;
  final bool showRelationships;
  final bool hasSelectedVertex;
  final bool hasSelectedShapes;
  final bool canUndo;
  final bool canRedo;

  final VoidCallback onToggleLinkMode;
  final VoidCallback onToggleEditVerticesMode;
  final VoidCallback onDeleteVertex;
  final VoidCallback onToggleShowRelationships;
  final VoidCallback onSendToFront;
  final VoidCallback onPushToBack;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onSave;
  final VoidCallback onLoad;

  const EditorAppBar({
    super.key,
    required this.isEditVerticesMode,
    required this.isLinkMode,
    required this.showRelationships,
    required this.hasSelectedVertex,
    required this.hasSelectedShapes,
    required this.canUndo,
    required this.canRedo,
    required this.onToggleLinkMode,
    required this.onToggleEditVerticesMode,
    required this.onDeleteVertex,
    required this.onToggleShowRelationships,
    required this.onSendToFront,
    required this.onPushToBack,
    required this.onUndo,
    required this.onRedo,
    required this.onSave,
    required this.onLoad,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        isEditVerticesMode
            ? 'Edit Vertices Mode'
            : isLinkMode
            ? 'Select 2 Shapes to Link'
            : 'Shape Operations',
      ),
      actions: <Widget>[
        _buildModeButton(
          label: 'Link Mode',
          icon: Icons.link,
          isActive: isLinkMode,
          activeColor: Colors.green,
          onPressed: onToggleLinkMode,
        ),
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
        if (!isLinkMode)
          IconButton(
            icon: Icon(
              showRelationships ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: onToggleShowRelationships,
            tooltip: showRelationships
                ? 'Hide relationships'
                : 'Show relationships',
          ),
        if (!isLinkMode)
          IconButton(
            icon: const Icon(Icons.vertical_align_top),
            onPressed: hasSelectedShapes ? onSendToFront : null,
            tooltip: 'Send selected shape to front',
          ),
        if (!isLinkMode)
          IconButton(
            icon: const Icon(Icons.vertical_align_bottom),
            onPressed: hasSelectedShapes ? onPushToBack : null,
            tooltip: 'Push selected shape to back',
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
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: onSave,
          tooltip: 'Save shapes',
        ),
        IconButton(
          icon: const Icon(Icons.folder_open),
          onPressed: onLoad,
          tooltip: 'Load shapes',
        ),
      ],
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
