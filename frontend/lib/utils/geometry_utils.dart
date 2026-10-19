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

  static Offset getPolygonCentroid(List<Offset> points) {
    if (points.isEmpty) return Offset.zero;
    if (points.length == 1) return points.first;

    double area = 0.0;
    double centroidX = 0.0;
    double centroidY = 0.0;

    for (int i = 0, j = points.length - 1; i < points.length; j = i++) {
      final Offset current = points[i];
      final Offset previous = points[j];
      final double cross = previous.dx * current.dy - current.dx * previous.dy;
      area += cross;
      centroidX += (previous.dx + current.dx) * cross;
      centroidY += (previous.dy + current.dy) * cross;
    }

    area *= 0.5;
    if (area.abs() < 1e-9) {
      return Offset(
        points.map((p) => p.dx).reduce((a, b) => a + b) / points.length,
        points.map((p) => p.dy).reduce((a, b) => a + b) / points.length,
      );
    }

    return Offset(centroidX / (6 * area), centroidY / (6 * area));
  }

  static Offset perpendicularVector(Offset v, {bool leftHand = true}) {
    return leftHand ? Offset(v.dy, -v.dx) : Offset(-v.dy, v.dx);
  }

  /// Whether segments p1-p2 and q1-q2 cross at a point interior to both.
  static bool segmentsCross(Offset p1, Offset p2, Offset q1, Offset q2) {
    double cross(Offset o, Offset a, Offset b) =>
        (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);
    final double d1 = cross(q1, q2, p1);
    final double d2 = cross(q1, q2, p2);
    final double d3 = cross(p1, p2, q1);
    final double d4 = cross(p1, p2, q2);
    return ((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
        ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0));
  }

  /// Whether the chord between vertices [i] and [j] cuts [polygon] into two
  /// polygons: the vertices are not neighbours and the chord stays inside.
  static bool isValidDiagonal(List<Offset> polygon, int i, int j) {
    final int n = polygon.length;
    if (i == j || (i - j).abs() == 1 || (i - j).abs() == n - 1) return false;

    final Offset a = polygon[i];
    final Offset b = polygon[j];
    if (a == b) return false;
    if (!isPointInPolygon((a + b) / 2, polygon)) return false;

    for (int k = 0; k < n; k++) {
      final int next = (k + 1) % n;
      if (k == i || k == j || next == i || next == j) continue;
      if (segmentsCross(a, b, polygon[k], polygon[next])) return false;
    }
    return true;
  }
}
