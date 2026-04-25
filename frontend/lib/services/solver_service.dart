import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:frontend/models/shape_data.dart';
import 'package:frontend/models/color_component.dart';
import 'package:frontend/models/comparison_operator.dart';

class SolverService {
  String baseUrl;

  SolverService({this.baseUrl = 'https://paint-constraints-api.devfriday.top'});

  Future<List<SolveResult>?> solve(
    List<ShapeRelationship> relationships,
  ) async {
    try {
      final requestBody = {
        'constraints': relationships
            .map(
              (r) => {
                'color': _mapComponent(r.relationship.component),
                'operation': _mapOperator(r.relationship.operator),
                'indexes': [r.sourceShapeIndex, r.targetShapeIndex],
                'offset': r.relationship.offset,
              },
            )
            .toList(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/solve'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => SolveResult.fromJson(item)).toList();
      } else {
        debugPrint('Solver error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Solver exception: $e');
      return null;
    }
  }

  String _mapComponent(ColorComponent component) {
    switch (component) {
      case ColorComponent.hue:
        return 'H';
      case ColorComponent.saturation:
        return 'S';
      case ColorComponent.value:
        return 'V';
    }
  }

  String _mapOperator(ComparisonOperator operator) {
    switch (operator) {
      case ComparisonOperator.lessThan:
        return 'LT';
      case ComparisonOperator.greaterThan:
        return 'GT';
      case ComparisonOperator.equal:
        return 'E';
      case ComparisonOperator.lessThanOrEqual:
        return 'LTE';
      case ComparisonOperator.greaterThanOrEqual:
        return 'GTE';
      case ComparisonOperator.notEqual:
        return 'NE';
    }
  }
}

class SolveResult {
  final int index;
  final double h;
  final double s;
  final double v;

  SolveResult({
    required this.index,
    required this.h,
    required this.s,
    required this.v,
  });

  factory SolveResult.fromJson(Map<String, dynamic> json) {
    return SolveResult(
      index: json['index'] as int,
      h: (json['h'] as num).toDouble(),
      s: (json['s'] as num).toDouble(),
      v: (json['v'] as num).toDouble(),
    );
  }
}
