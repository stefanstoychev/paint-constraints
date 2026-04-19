import 'package:flutter/material.dart';
import 'package:frontend/controllers/project_manager.dart';
import 'package:frontend/models/canvas_project.dart';
import 'package:frontend/widgets/canvas_thumbnail.dart';
import 'package:frontend/widgets/shape_editor.dart';
import 'package:provider/provider.dart';

class GalleryView extends StatelessWidget {
  const GalleryView({super.key});

  @override
  Widget build(BuildContext context) {
    final projectManager = context.watch<ProjectManager>();

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, projectManager),
        icon: const Icon(Icons.add),
        label: const Text('New Painting'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SafeArea(
        child: projectManager.isLoading
            ? const Center(child: CircularProgressIndicator())
            : projectManager.projects.isEmpty
                ? _buildEmptyState(context, projectManager)
                : _buildGrid(context, projectManager.projects),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ProjectManager manager) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.palette_outlined, size: 100, color: Colors.grey.shade700),
          const SizedBox(height: 16),
          const Text(
            'No paintings yet',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateDialog(context, manager),
            icon: const Icon(Icons.add),
            label: const Text('Create Your First Canvas'),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<CanvasProject> projects) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return CanvasThumbnail(
          project: project,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ShapeEditor(project: project),
            ),
          ),
          onDelete: () => _showDeleteConfirm(context, projectManager: context.read<ProjectManager>(), project: project),
        );
      },
    );
  }

  void _showCreateDialog(BuildContext context, ProjectManager manager) {
    final nameController = TextEditingController();
    Size selectedSize = const Size(460, 320); // Default medium

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New Canvas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Painting Name',
                  hintText: 'My Masterpiece',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 20),
              const Text('Dimensions', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildSizeOption(
                label: 'Small (300x200)',
                size: const Size(300, 200),
                current: selectedSize,
                onSelect: (s) => setState(() => selectedSize = s),
              ),
              _buildSizeOption(
                label: 'Medium (460x320)',
                size: const Size(460, 320),
                current: selectedSize,
                onSelect: (s) => setState(() => selectedSize = s),
              ),
              _buildSizeOption(
                label: 'Large (600x450)',
                size: const Size(600, 450),
                current: selectedSize,
                onSelect: (s) => setState(() => selectedSize = s),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                try {
                  final project = await manager.createProject(name, selectedSize);
                  if (context.mounted) {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ShapeEditor(project: project),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeOption({
    required String label,
    required Size size,
    required Size current,
    required ValueChanged<Size> onSelect,
  }) {
    return RadioListTile<Size>(
      title: Text(label),
      value: size,
      groupValue: current,
      onChanged: (s) => onSelect(s!),
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showDeleteConfirm(BuildContext context, {required ProjectManager projectManager, required CanvasProject project}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Painting'),
        content: Text('Are you sure you want to delete "${project.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              projectManager.deleteProject(project.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
