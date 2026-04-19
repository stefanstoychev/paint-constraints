import 'dart:math';
import 'package:flutter/material.dart';

class GeometryUtils {
  /// Checks if a given point is inside a polygon defined by a list of points.
  static bool isPointInPolygon(Offset point, List<Offset> polygon) {
    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final Offset pI = polygon[i];
      final Offset pJ = polygon[j];

      if (((pI.dy > point.dy) != (pJ.dy > point.dy)) &&
          (point.dx <
              (pJ.dx - pI.dx) * (point.dy - pI.dy) / (pJ.dy - pI.dy) + pI.dx)) {
        inside = !inside;
      }
    }
    return inside;
  }

  /// Calculates the shortest distance from a point to a line segment.
  static double distanceToSegment(Offset p, Offset p1, Offset p2) {
    final double l2 = (pow(p2.dx - p1.dx, 2) + pow(p2.dy - p1.dy, 2))
        .toDouble();
    if (l2 == 0.0) return (p - p1).distance;

    final double t =
        ((p.dx - p1.dx) * (p2.dx - p1.dx) + (p.dy - p1.dy) * (p2.dy - p1.dy)) /
        l2;

    late Offset projection;
    if (t < 0.0) {
      projection = p1;
    } else if (t > 1.0) {
      projection = p2;
    } else {
      projection = Offset(
        p1.dx + t * (p2.dx - p1.dx),
        p1.dy + t * (p2.dy - p1.dy),
      );
    }
    return (p - projection).distance;
  }
}
