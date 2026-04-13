import 'dart:convert';

import 'package:frontend/models/canvas_data.dart';
import 'package:frontend/models/shape_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  Future<void> save(CanvasData data) async {
    final prefs = await SharedPreferences.getInstance();
    final shapesJson = jsonEncode(data.shapes.map((s) => s.toJson()).toList());
    final relationshipsJson = jsonEncode(
      data.relationships.map((r) => r.toJson()).toList(),
    );

    await prefs.setString('saved_shapes', shapesJson);
    await prefs.setString('saved_relationships', relationshipsJson);
  }

  Future<CanvasData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final shapesJson = prefs.getString('saved_shapes');
    final relationshipsJson = prefs.getString('saved_relationships');

    final List<dynamic> shapesDecoded = jsonDecode(shapesJson!);
    final List<ShapeRelationship> relationshipsDecoded =
        relationshipsJson != null
        ? (jsonDecode(relationshipsJson) as List<dynamic>)
              .map(
                (item) =>
                    ShapeRelationship.fromJson(item as Map<String, dynamic>),
              )
              .toList()
        : <ShapeRelationship>[];

    List<ShapeData> allShapes = shapesDecoded
        .map((item) => ShapeData.fromJson(item as Map<String, dynamic>))
        .toList();

    return CanvasData(shapes: allShapes, relationships: relationshipsDecoded);
  }
}
