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

class WhiteboardCanvas extends StatefulHookConsumerWidget {
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
  final ValueNotifier<Offset> canvasPos;
  final ValueNotifier<Offset> startPos;

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
      required this.backgroundImage,
      required this.canvasPos,
      required this.startPos})
      : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      WhiteboardCanvasState();
}

class WhiteboardCanvasState extends ConsumerState<WhiteboardCanvas> {
  Offset _canvasPos = Offset(0, 0);

  @override
  Widget build(BuildContext context) {
    Offset _startPos = widget.startPos.value;
    return MouseRegion(
      cursor: SystemMouseCursors.precise,
      child: GestureDetector(
          onSecondaryTap: () => showOptions(context, widget.eraserSize,
              widget.strokeSize, widget.selectedColor),
          onPanStart: (details) => {
                setState(() {
                  if (widget.drawingMode.value == DrawingModes.pan) {
                    _startPos = details.localPosition;
                  }
/*
                  else {
                    setState(() {
                      widget.startPos.value = details.localPosition;
                    });
                  }
                        */
                })
              },
          onPanUpdate: (details) => {
                if (widget.drawingMode.value == DrawingModes.pan)
                  {
                    setState(() {
                      widget.canvasPos.value += details.delta;
                      widget.startPos.value = details.localPosition;
                    })
                  }
                //NOTE: This causes canvasposition to change alot
                /*
                else
                  {
                    setState(() {
                      widget.canvasPos.value +=
                          details.localPosition - widget.startPos.value;
                      widget.startPos.value = details.localPosition;
                    })
                  }
                */
              },
          child: Stack(
            children: [
              Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  color: Colors.black),
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

    widget.currentSketch.value = Sketch.fromDrawingMode(
        Sketch(
            vectors: [offset],
            size: widget.drawingMode.value == DrawingModes.eraser
                ? widget.eraserSize.value
                : widget.strokeSize.value,
            color: widget.drawingMode.value == DrawingModes.eraser
                ? kCanvasColor
                : widget.selectedColor.value,
            shapeSides: widget.shapeSides.value),
        widget.drawingMode.value,
        widget.filled.value);
  }

  void onPointerMove(PointerMoveEvent details, BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.globalToLocal(details.position);
    final vectors = List<Offset>.from(widget.currentSketch.value?.vectors ?? [])
      ..add(offset);
    widget.currentSketch.value = Sketch.fromDrawingMode(
        Sketch(
            vectors: vectors,
            size: widget.drawingMode.value == DrawingModes.eraser
                ? widget.eraserSize.value
                : widget.strokeSize.value,
            color: widget.drawingMode.value == DrawingModes.eraser
                ? kCanvasColor
                : widget.selectedColor.value,
            shapeSides: widget.shapeSides.value),
        widget.drawingMode.value,
        widget.filled.value);
  }

  void onPointerUp(PointerUpEvent details) {
    widget.allSketches.value = List<Sketch>.from(widget.allSketches.value)
      ..add(widget.currentSketch.value!);
    widget.currentSketch.value = Sketch.fromDrawingMode(
        Sketch(
            vectors: [],
            size: widget.drawingMode.value == DrawingModes.eraser
                ? widget.eraserSize.value
                : widget.strokeSize.value,
            color: widget.drawingMode.value == DrawingModes.eraser
                ? kCanvasColor
                : widget.selectedColor.value,
            shapeSides: widget.shapeSides.value),
        widget.drawingMode.value,
        widget.filled.value);
  }

//TODO: Refactor these smaller widgets somewhere else
  Widget buildAllSketches(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: ValueListenableBuilder<List<Sketch>>(
        valueListenable: widget.allSketches,
        builder: (context, sketches, _) {
          return RepaintBoundary(
            key: widget.whiteboardCanvasKey,
            child: Container(
              height: widget.height,
              width: widget.width,
              color: kCanvasColor,
              child: CustomPaint(
                painter: SketchPainter(
                    canvasPos: widget.canvasPos.value,
                    drawingMode: widget.drawingMode.value,
                    sketches: sketches,
                    bgImage: widget.backgroundImage.value),
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
        valueListenable: widget.currentSketch,
        builder: (context, sketch, child) {
          return RepaintBoundary(
            child: SizedBox(
              height: widget.height,
              width: widget.width,
              child: CustomPaint(
                painter: SketchPainter(
                  canvasPos: widget.canvasPos.value,
                  drawingMode: widget.drawingMode.value,
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
  final Offset canvasPos;
  final DrawingModes drawingMode;
  final ValueNotifier<List<Sketch>> sketches;

  const BuildAllSketches(
      {super.key,
      required this.height,
      required this.width,
      required this.canvasKey,
      this.bgImage,
      required this.canvasPos,
      required this.drawingMode,
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
                painter: SketchPainter(
                    canvasPos: canvasPos,
                    drawingMode: drawingMode,
                    sketches: sketches.value,
                    bgImage: bgImage),
              ),
            ),
          );
        },
      ),
    );
  }
}
