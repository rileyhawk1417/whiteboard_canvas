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
    //Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    //Paint background = Paint();
    //background.color = Colors.blueAccent;
    //canvas.drawRect(rect, background);
    //canvas.clipRect(rect);
    //canvas.scale(2.0);
    for (Sketch sketch in sketches) {
      final vectors = sketch.vectors;
      if (vectors.isEmpty) return;

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

      Rect rect = Rect.fromPoints(vectorStart, vectorEnd);

      switch (sketch.sketchType) {
        case SketchType.scribble:
          canvas.drawPath(vectorPath, painter);
        case SketchType.line:
          canvas.drawLine(vectorStart, vectorEnd, painter);
        case SketchType.square:
          canvas.drawRRect(
              RRect.fromRectAndRadius(rect, const Radius.circular(5)), painter);
        case SketchType.circle:
          canvas.drawOval(rect, painter);
        case SketchType.polygon:

          // Get the center vector between start & end
          Offset centerVector = (vectorStart / 2) + (vectorEnd / 2);

          //Calculate vectorpath radius from start & end
          double radius = (vectorStart - vectorEnd).distance / 2;
          Path polyPath = Path();
          int sides = sketch.shapeSides;
          var angle = (math.pi * 2) / sides;
          double radian = 0.0;

          Offset startVector =
              Offset(radius * math.cos(radian), radius * math.sin(radian));
          polyPath.moveTo(startVector.dx + centerVector.dx,
              startVector.dy + centerVector.dy);

          for (int idx = 1; idx <= sides; idx++) {
            double x =
                radius * math.cos(radian + angle * idx) + centerVector.dx;
            double y =
                radius * math.sin(radian + angle * idx) + centerVector.dy;
            polyPath.lineTo(x, y);
          }
          polyPath.close();
          canvas.drawPath(polyPath, painter);
        default:
      }
    }
  }

  @override
  bool shouldRepaint(CanvasPainter oldDelegate) {
    return true;
  }
}
