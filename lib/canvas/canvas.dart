import 'dart:math' as math;
import 'dart:ui';

import 'package:drawing_canvas/canvas/models/sketch_painter.dart';
import 'package:drawing_canvas/canvas/widgets/toolbar.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:drawing_canvas/canvas/models/sketch_model.dart';
import 'package:drawing_canvas/canvas/models/drawing_modes.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const Color kCanvasColor = Color(0xfff2f3f7);

class WhiteboardCanvas extends HookWidget {
  final double height;
  final double width;
  final ValueNotifier<Color> selectedColor;
  final ValueNotifier<double> strokeSize;
  final ValueNotifier<Image?> backgroundImage;
  final ValueNotifier<double> eraserSize;
  final ValueNotifier<DrawingModes> drawingMode;
  // TODO: add drawing tool presets.
  final AnimationController sideBarController;
  final ValueNotifier<Sketch?> currentSketch;
  final ValueNotifier<List<Sketch>> allSketches;
  final GlobalKey whiteboardCanvasKey;
  final ValueNotifier<int> shapeSides;
  final ValueNotifier<bool> filled;

  const WhiteboardCanvas(
      {Key? key,
      required this.height,
      required this.width,
      required this.eraserSize,
      required this.selectedColor,
      required this.drawingMode,
      required this.currentSketch,
      required this.allSketches,
      required this.whiteboardCanvasKey,
      required this.filled,
      required this.shapeSides,
      required this.strokeSize,
      required this.sideBarController,
      required this.backgroundImage})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.precise,
      child: GestureDetector(
          onSecondaryTap: () =>
              showOptions(context, eraserSize, strokeSize, selectedColor),
          child: Stack(
            children: [
              buildAllSketches(context),
              buildCurrentSketch(context),
            ],
          )),
    );
  }

  void onPointerDown(PointerDownEvent details, BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.globalToLocal(details.position);
    //NOTE: Calling the right Click gesture here will disrupt the normal drawing op
    //NOTE: Causes the need to perform a hard restart.
    //if((details.buttons && kSecondaryButton) != 0){}

    currentSketch.value = Sketch.fromDrawingMode(
        Sketch(
            vectors: [offset],
            size: drawingMode.value == DrawingModes.eraser
                ? eraserSize.value
                : strokeSize.value,
            color: drawingMode.value == DrawingModes.eraser
                ? kCanvasColor
                : selectedColor.value,
            shapeSides: shapeSides.value),
        drawingMode.value,
        filled.value);
  }

  void onPointerMove(PointerMoveEvent details, BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.globalToLocal(details.position);
    final vectors = List<Offset>.from(currentSketch.value?.vectors ?? [])
      ..add(offset);
    currentSketch.value = Sketch.fromDrawingMode(
        Sketch(
            vectors: vectors,
            size: drawingMode.value == DrawingModes.eraser
                ? eraserSize.value
                : strokeSize.value,
            color: drawingMode.value == DrawingModes.eraser
                ? kCanvasColor
                : selectedColor.value,
            shapeSides: shapeSides.value),
        drawingMode.value,
        filled.value);
  }

  void onPointerUp(PointerUpEvent details) {
    allSketches.value = List<Sketch>.from(allSketches.value)
      ..add(currentSketch.value!);
    currentSketch.value = Sketch.fromDrawingMode(
        Sketch(
            vectors: [],
            size: drawingMode.value == DrawingModes.eraser
                ? eraserSize.value
                : strokeSize.value,
            color: drawingMode.value == DrawingModes.eraser
                ? kCanvasColor
                : selectedColor.value,
            shapeSides: shapeSides.value),
        drawingMode.value,
        filled.value);
  }

//TODO: Refactor these smaller widgets somewhere else
  Widget buildAllSketches(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: ValueListenableBuilder<List<Sketch>>(
        valueListenable: allSketches,
        builder: (context, sketches, _) {
          return RepaintBoundary(
            key: whiteboardCanvasKey,
            child: Container(
              height: height,
              width: width,
              color: kCanvasColor,
              child: CustomPaint(
                painter: SketchPainter(
                    sketches: sketches, bgImage: backgroundImage.value),
              ),
            ),
          );
        },
      ),
    );
  }

//TODO: Refactor these smaller widgets somewhere else
  Widget buildCurrentSketch(BuildContext context) {
    return Listener(
      onPointerDown: (details) => onPointerDown(details, context),
      onPointerMove: (details) => onPointerMove(details, context),
      onPointerUp: onPointerUp,
      child: ValueListenableBuilder(
        valueListenable: currentSketch,
        builder: (context, sketch, child) {
          return RepaintBoundary(
            child: SizedBox(
              height: height,
              width: width,
              child: CustomPaint(
                painter: SketchPainter(
                  sketches: sketch == null ? [] : [sketch],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class BuildAllSketches extends ConsumerWidget {
  final double height;
  final double width;
  final GlobalKey canvasKey;
  final Image? bgImage;
  final ValueNotifier<List<Sketch>> sketches;

  const BuildAllSketches(
      {super.key,
      required this.height,
      required this.width,
      required this.canvasKey,
      this.bgImage,
      required this.sketches});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: height,
      width: width,
      child: ValueListenableBuilder<List<Sketch>>(
        valueListenable: sketches,
        builder: (context, sketch, _) {
          return RepaintBoundary(
            key: canvasKey,
            child: Container(
              height: height,
              width: width,
              color: kCanvasColor,
              child: CustomPaint(
                painter:
                    SketchPainter(sketches: sketches.value, bgImage: bgImage),
              ),
            ),
          );
        },
      ),
    );
  }
}
