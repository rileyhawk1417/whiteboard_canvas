import 'package:drawing_canvas/canvas/models/sketch_model.dart';
import 'package:flutter/material.dart' hide Image;
import 'dart:math' as math;
import 'dart:ui';

class SketchPainter extends CustomPainter {
  final List<Sketch> sketches;
  final Image? bgImage;

  const SketchPainter({
    Key? key,
    this.bgImage,
    required this.sketches,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bgImage != null) {
      canvas.drawImageRect(
        bgImage!,
        Rect.fromLTWH(
          0,
          0,
          bgImage!.width.toDouble(),
          bgImage!.height.toDouble(),
        ),
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint(),
      );
    }
    // Get the vector points drawn
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

      // Get start & end of vector points
      Offset vectorStart = sketch.vectors.first;
      Offset vectorEnd = sketch.vectors.last;

      // Create shapes, can be circle or rectangle
      Rect rect = Rect.fromPoints(vectorStart, vectorEnd);

      // Get the center vector between start & end
      Offset centerVector = (vectorStart / 2) + (vectorEnd / 2);

      //Calculate vectorpath radius from start & end
      double radius = (vectorStart - vectorEnd).distance / 2;

      if (sketch.sketchType == SketchType.scribble) {
        canvas.drawPath(vectorPath, painter);
      } else if (sketch.sketchType == SketchType.square) {
        //NOTE: Possibly add a custom radius option here?
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(5)), painter);
      } else if (sketch.sketchType == SketchType.line) {
        canvas.drawLine(vectorStart, vectorEnd, painter);
      } else if (sketch.sketchType == SketchType.circle) {
        canvas.drawOval(rect, painter);
        //TODO: support perfect circle at some point...
        //For a perfect circle uncomment the following:
        // canvas.drawCircle(centerVector, radius, painter);
      } else if (sketch.sketchType == SketchType.polygon) {
        Path polyPath = Path();
        int sides = sketch.shapeSides;
        var angle = (math.pi * 2) / sides;
        double radian = 0.0;

        Offset startVector =
            Offset(radius * math.cos(radian), radius * math.sin(radian));
        polyPath.moveTo(
            startVector.dx + centerVector.dx, startVector.dy + centerVector.dy);

        for (int idx = 1; idx <= sides; idx++) {
          double x = radius * math.cos(radian + angle * idx) + centerVector.dx;
          double y = radius * math.sin(radian + angle * idx) + centerVector.dy;
          polyPath.lineTo(x, y);
        }
        polyPath.close();
        canvas.drawPath(polyPath, painter);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SketchPainter oldDelegate) {
    return oldDelegate.sketches != sketches;
  }
}
