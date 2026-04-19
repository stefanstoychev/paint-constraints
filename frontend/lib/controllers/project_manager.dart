import 'package:flutter/material.dart';
import 'package:frontend/models/canvas_data.dart';
import 'package:frontend/models/canvas_project.dart';
import 'package:frontend/storage_service.dart';

class ProjectManager extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  List<CanvasProject> _projects = [];
  bool _isLoading = true;

  ProjectManager() {
    loadProjects();
  }

  List<CanvasProject> get projects => _projects;
  bool get isLoading => _isLoading;

  Future<void> loadProjects() async {
    _isLoading = true;
    notifyListeners();
    _projects = await _storageService.loadAllProjects();
    _isLoading = false;
    notifyListeners();
  }

  Future<CanvasProject> createProject(String name, Size dimensions) async {
    if (_projects.any((p) => p.name == name)) {
      throw Exception('Project name must be unique');
    }

    final project = CanvasProject(
      id: '${DateTime.now().millisecondsSinceEpoch}_$name',
      name: name,
      canvasRect: Rect.fromLTWH(20, 20, dimensions.width, dimensions.height),
      data: CanvasData(shapes: [], relationships: []),
      lastModified: DateTime.now(),
    );

    _projects.add(project);
    await _storageService.saveProject(project);
    notifyListeners();
    return project;
  }

  Future<void> deleteProject(String id) async {
    _projects.removeWhere((p) => p.id == id);
    await _storageService.deleteProject(id);
    notifyListeners();
  }

  Future<void> updateProject(CanvasProject project) async {
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      _projects[index] = project.copyWith(lastModified: DateTime.now());
      await _storageService.saveProject(_projects[index]);
      notifyListeners();
    }
  }
}
