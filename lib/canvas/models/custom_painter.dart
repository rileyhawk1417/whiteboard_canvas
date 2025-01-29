import 'package:drawing_canvas/canvas/models/drawing_modes.dart';
import 'package:drawing_canvas/canvas/models/sketch_model.dart';
import 'package:flutter/material.dart' hide Image;
import 'dart:math' as math;
import 'dart:ui';

class CanvasPainter extends CustomPainter {
  final List<Offset>? points;
  final List<Sketch> sketches;

  CanvasPainter({this.points, required this.sketches});

  @override
  void paint(Canvas canvas, Size size) {
    Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    Paint background = Paint();
    background.color = Colors.blueAccent;
    canvas.drawRect(rect, background);
    //canvas.clipRect(rect);
    //canvas.scale(2.0);
    /*
    for (var item in points) {
      final vectorPath = Path();
      vectorPath.moveTo(item.dx, item.dy);
      canvas.drawPath(vectorPath, paint);
    }
        */

    /*
    for (var point in points) {
      if (points.isEmpty) return;
      // vectorPath.moveTo(points[0].dx, points[0].dy);
      // canvas.drawPath(vectorPath, paint);
      canvas.drawLine(point, points[points.length - 1], paint);
    }
        */
    /*
    for (int i = 0; i < points.length - 1; i++) {
      final vecPath = Path();
      if (points[i] != null && points[i + 1] != null) {
        vecPath.moveTo(points[i + 1].dx, points[i + 1].dy);
        //canvas.drawLine(points[i + 1]!, points[i + 1]!, paint);
        print('Vector path in custom paint');
        print(vecPath);
        canvas.drawPath(vecPath, paint);
      }
    }
        */
    for (Sketch sketch in sketches) {
      final vectors = sketch.vectors;
      if (vectors.isEmpty) return;
      print(vectors);
      final vectorPath = Path();
      vectorPath.moveTo(vectors[0].dx, vectors[0].dy);

      if (vectors.length < 2) {
        //If Vector path has more than one line draw a dot.
        vectorPath.addOval(
          Rect.fromCircle(
              center: Offset(vectors[0].dx, vectors[0].dy), radius: 1),
        );
      }

      for (int index = 1; index < vectors.length - 1; ++index) {
        final v0 = vectors[index];
        final v1 = vectors[index + 1];
        vectorPath.quadraticBezierTo(
            v0.dx, v0.dy, (v0.dx + v1.dx) / 2, (v0.dy + v1.dy) / 2);
      }
      // Define paint
      Paint painter = Paint()
        ..color = sketch.color
        ..strokeCap = StrokeCap.round;

      if (!sketch.filled) {
        painter.style = PaintingStyle.stroke;
        painter.strokeWidth = sketch.size;
      }
      Offset vectorStart = sketch.vectors.first;
      Offset vectorEnd = sketch.vectors.last;

      if (sketch.sketchType == SketchType.scribble) {
        canvas.drawPath(vectorPath, painter);
      }
      if (sketch.sketchType == SketchType.line) {
        canvas.drawLine(vectorStart, vectorEnd, painter);
      }
    }
  }

  @override
  bool shouldRepaint(CanvasPainter oldDelegate) {
    //return oldDelegate.sketches != sketches;
    return true;
  }
}
