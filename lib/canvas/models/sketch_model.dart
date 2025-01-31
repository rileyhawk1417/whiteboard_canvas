import 'package:flutter/material.dart';
import 'package:drawing_canvas/canvas/models/drawing_modes.dart';

//TODO: Refactor this class to a freezed model once its working.
//TODO: Change to abstract class in order to use copyWith.
class Sketch {
  final List<Offset> vectors;
  final Color color;
  final double size;
  final SketchType sketchType;
  final bool filled;
  final int shapeSides;

  Sketch(
      {required this.vectors,
      required this.size,
      this.color = Colors.black,
      this.sketchType = SketchType.scribble,
      this.filled = true,
      this.shapeSides = 3});

  factory Sketch.fromDrawingMode(
      Sketch sketch, DrawingModes drawingMode, bool filled) {
    return Sketch(
        vectors: sketch.vectors,
        color: sketch.color,
        size: sketch.size,
        filled: checkDrawingTypeFill(drawingMode) ? false : filled,
        shapeSides: sketch.shapeSides,
        sketchType: checkDrawingType(drawingMode));
  }

  Map<String, dynamic> toJson() {
    List<Map> vectorMap = vectors.map((e) => {'dx': e.dx, 'dy': e.dy}).toList();
    return {
      'vectors': vectorMap,
      'color': color.toHex(),
      'size': size,
      'filled': filled,
      'sketchType': sketchType.toRegularString(),
      'shapeSides': shapeSides
    };
  }

  factory Sketch.fromJson(Map<String, dynamic> json) {
    List<Offset> vectorMap =
        (json['vectors'] as List).map((e) => Offset(e['dx'], e['dy'])).toList();
    Sketch returnValue = Sketch(
        vectors: vectorMap,
        size: json['size'],
        color: (json['color'] as String).toColor(),
        shapeSides: json['shapeSides'],
        filled: json['filled'],
        sketchType: (json['sketchType'] as String).toSketchTypeEnum());
    return returnValue;
  }
}

enum SketchType { scribble, line, square, circle, polygon, eraser, pan }

bool checkDrawingTypeFill(DrawingModes mode) {
  switch (mode) {
    case DrawingModes.line:
      return true;
    case DrawingModes.pencil:
      return true;
    case DrawingModes.eraser:
      return true;
    default:
      return false;
  }
}

SketchType checkDrawingType(DrawingModes mode) {
  switch (mode) {
    case DrawingModes.eraser:
      return SketchType.scribble;
    case DrawingModes.line:
      return SketchType.line;
    case DrawingModes.pencil:
      return SketchType.scribble;
    case DrawingModes.square:
      return SketchType.square;
    case DrawingModes.circle:
      return SketchType.circle;
    case DrawingModes.polygon:
      return SketchType.polygon;
    case DrawingModes.pan:
      return SketchType.pan;
    default:
      return SketchType.scribble;
  }
}

extension SketchTypeData on SketchType {
  String toRegularString() => toString().split('.')[1];
}

extension SketchTypeExt on String {
  SketchType toSketchTypeEnum() =>
      SketchType.values.firstWhere((e) => e.toString() == 'SketchType.$this');
}

extension ColorExt on String {
  Color toColor() {
    String hexColor = replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    if (hexColor.length == 8) {
      return Color(int.parse('0x$hexColor'));
    } else {
      return Colors.black;
    }
  }
}

extension ColorExtType on Color {
  String toHex() => '#${value.toRadixString(16).substring(2, 8)}';
}
