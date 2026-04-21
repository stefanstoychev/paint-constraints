import 'dart:convert';

import 'package:frontend/models/canvas_project.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  Future<void> saveProject(CanvasProject project) async {
    final prefs = await SharedPreferences.getInstance();
    final projectJson = jsonEncode(project.toJson());
    await prefs.setString('project_${project.id}', projectJson);

    // Update project list if not already there
    final List<String> projectIds = prefs.getStringList('project_ids') ?? [];
    if (!projectIds.contains(project.id)) {
      projectIds.add(project.id);
      await prefs.setStringList('project_ids', projectIds);
    }
  }

  Future<List<CanvasProject>> loadAllProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> projectIds = prefs.getStringList('project_ids') ?? [];
    
    final List<CanvasProject> projects = [];
    for (final id in projectIds) {
      final projectJson = prefs.getString('project_$id');
      if (projectJson != null) {
        projects.add(CanvasProject.fromJson(jsonDecode(projectJson)));
      }
    }
    return projects;
  }

  Future<void> deleteProject(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('project_$id');
    
    final List<String> projectIds = prefs.getStringList('project_ids') ?? [];
    projectIds.remove(id);
    await prefs.setStringList('project_ids', projectIds);
  }
}
