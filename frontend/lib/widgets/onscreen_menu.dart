import 'package:flutter/material.dart';

class OnscreenMenu extends StatelessWidget {
  final bool isEditVerticesMode;
  final bool isLinkMode;
  final bool hasSelectedVertex;
  final VoidCallback onToggleLinkMode;
  final VoidCallback onToggleEditVerticesMode;
  final VoidCallback onDeleteVertex;

  const OnscreenMenu({
    super.key,
    required this.isEditVerticesMode,
    required this.isLinkMode,
    required this.hasSelectedVertex,
    required this.onToggleLinkMode,
    required this.onToggleEditVerticesMode,
    required this.onDeleteVertex,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      left: 20,
      child: Card(
        elevation: 4,
        color: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
        color: isActive ? activeColor.withOpacity(0.15) : Colors.transparent,
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
