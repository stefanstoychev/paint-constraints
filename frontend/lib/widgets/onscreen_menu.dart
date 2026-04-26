import 'package:flutter/material.dart';

class OnscreenMenu extends StatelessWidget {
  final bool isEditVerticesMode;
  final bool isLinkMode;
  final bool isHueVisible;
  final bool isSatVisible;
  final bool isValueVisible;
  final bool hasSelectedVertex;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onToggleLinkMode;
  final VoidCallback onToggleEditVerticesMode;
  final VoidCallback onToggleHueVisible;
  final VoidCallback onToggleSatVisible;
  final VoidCallback onToggleValueVisible;
  final VoidCallback onDeleteVertex;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  const OnscreenMenu({
    super.key,
    required this.isEditVerticesMode,
    required this.isLinkMode,
    required this.isHueVisible,
    required this.isSatVisible,
    required this.isValueVisible,
    required this.hasSelectedVertex,
    required this.onToggleLinkMode,
    required this.onToggleHueVisible,
    required this.onToggleSatVisible,
    required this.onToggleValueVisible,
    required this.onToggleEditVerticesMode,
    required this.onDeleteVertex,
    required this.onUndo,
    required this.onRedo,
    required this.canUndo,
    required this.canRedo,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      left: 20,
      child: Card(
        elevation: 4,
        color: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MenuButton(
                icon: Icons.link,
                isActive: isLinkMode,
                activeColor: Colors.greenAccent,
                onPressed: onToggleLinkMode,
                tooltip: 'Link Mode',
              ),
              if (isLinkMode) ...[
                const Divider(color: Colors.white24, height: 16),
                _MenuButtonLetter(
                  letter: "H",
                  isActive: isHueVisible,
                  activeColor: Colors.lightBlue,
                  onPressed:onToggleHueVisible,
                  tooltip: 'Toggle hue',
                  disabledColor: Colors.white24,
                ),
                _MenuButtonLetter(
                  letter: "S",
                  isActive: isSatVisible,
                  activeColor: Colors.lightBlue,
                  onPressed: onToggleSatVisible,
                  tooltip: 'Toggle saturation',
                  disabledColor: Colors.white24,
                ),
                _MenuButtonLetter(
                  letter: "V",
                  isActive: isValueVisible,
                  activeColor: Colors.lightBlue,
                  onPressed: onToggleValueVisible,
                  tooltip: 'Toggle value',
                  disabledColor: Colors.white24,
                ),
              ],
              const SizedBox(height: 8),
              _MenuButton(
                icon: Icons.scatter_plot,
                isActive: isEditVerticesMode,
                activeColor: Colors.blueAccent,
                onPressed: onToggleEditVerticesMode,
                tooltip: 'Edit Vertices',
              ),
              if (isEditVerticesMode) ...[
                const Divider(color: Colors.white24, height: 16),
                _MenuButton(
                  icon: Icons.delete_outline,
                  isActive: hasSelectedVertex,
                  activeColor: Colors.redAccent,
                  onPressed: hasSelectedVertex ? onDeleteVertex : null,
                  tooltip: 'Delete Selected Vertex',
                  disabledColor: Colors.white24,
                ),
              ],
              _MenuButton(
                icon: Icons.redo,
                isActive: canRedo,
                activeColor: Colors.blueGrey,
                onPressed: canRedo ? onRedo : null,
                tooltip: 'Redo',
                disabledColor: Colors.white24,
              ),
              _MenuButton(
                icon: Icons.undo,
                isActive: canUndo,
                activeColor: Colors.grey,
                onPressed: canUndo ? onUndo : null,
                tooltip: 'Undo',
                disabledColor: Colors.white24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color? disabledColor;

  const _MenuButton({
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onPressed,
    required this.tooltip,
    this.disabledColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? activeColor.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: onPressed == null
              ? (disabledColor ?? Colors.grey)
              : (isActive ? activeColor : Colors.white70),
        ),
        onPressed: onPressed,
        tooltip: tooltip,
        splashRadius: 24,
      ),
    );
  }
}

class _MenuButtonLetter extends StatelessWidget {
  final String letter;
  final bool isActive;
  final Color activeColor;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color? disabledColor;

  const _MenuButtonLetter({
    required this.letter,
    required this.isActive,
    required this.activeColor,
    required this.onPressed,
    required this.tooltip,
    this.disabledColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? activeColor.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Text(
          letter,
          style: TextStyle(
            color: onPressed == null
                ? (disabledColor ?? Colors.grey)
                : (isActive ? activeColor : Colors.white70),
          ),
        ),
        onPressed: onPressed,
        tooltip: tooltip,
        splashRadius: 24,
      ),
    );
  }
}