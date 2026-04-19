import 'package:flutter/material.dart';
import 'package:frontend/models/canvas_project.dart';

class CanvasThumbnail extends StatelessWidget {
  final CanvasProject project;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const CanvasThumbnail({
    super.key,
    required this.project,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        color: Colors.grey.shade800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.palette, size: 64, color: Colors.white24),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${project.canvasRect.width.toInt()}x${project.canvasRect.height.toInt()}',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          project.lastModified.toIso8601String(),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.white38,
                    ),
                    onPressed: onDelete,
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
