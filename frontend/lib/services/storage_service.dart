import 'dart:convert';

import 'package:frontend/models/canvas_project.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // Private constants for all static keys used in SharedPreferences
  static const String _projectIdsKey = 'project_ids';

  Future<SharedPreferences> _getPrefs() async {
    // The original implementation already does this correctly, but wrapping it in
    // a private getter method abstracts away the boilerplate call site logic.
    return await SharedPreferences.getInstance();
  }

  /// Constructs the unique storage key for a specific project ID (e.g., "project_abc123").
  String _getProjectKey(String projectId) {
    return 'project_$projectId';
  }

  Future<void> saveProject(CanvasProject project) async {
    final prefs = await _getPrefs();
    final projectJson = jsonEncode(project.toJson());
    // Use the helper method to generate a safe key.
    await prefs.setString(_getProjectKey(project.id), projectJson);

    // Update project list if not already there using the constant key.
    final List<String> projectIds = prefs.getStringList(_projectIdsKey) ?? [];
    if (!projectIds.contains(project.id)) {
      projectIds.add(project.id);
      await prefs.setStringList(_projectIdsKey, projectIds);
    }
  }

  Future<List<CanvasProject>> loadAllProjects() async {
    final prefs = await _getPrefs();
    // Use the constant key to retrieve the list of IDs.
    final List<String> projectIds = prefs.getStringList(_projectIdsKey) ?? [];

    final List<CanvasProject> projects = [];
    for (final id in projectIds) {
      // Use the helper method to generate a safe key for loading.
      final projectJson = prefs.getString(_getProjectKey(id));
      if (projectJson != null) {
        projects.add(CanvasProject.fromJson(jsonDecode(projectJson)));
      }
    }
    return projects;
  }

  Future<void> deleteProject(String id) async {
    final prefs = await _getPrefs();
    // Use the helper method to generate a safe key for deletion.
    await prefs.remove(_getProjectKey(id));

    final List<String> projectIds = prefs.getStringList(_projectIdsKey) ?? [];
    projectIds.remove(id); 
    await prefs.setStringList(_projectIdsKey, projectIds);
  }
}
