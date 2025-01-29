import 'dart:math' as math;
import 'dart:ui';

import 'package:drawing_canvas/canvas/models/custom_painter.dart';
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

_calculateOffset(Offset offset, double scale) {
  return offset / scale;
}

class WhiteboardCanvasState extends ConsumerState<WhiteboardCanvas> {
  final ValueNotifier<Size> canvasSizeNotifier =
      ValueNotifier(Size(5000, 5000));
  final TransformationController _transformController =
      TransformationController();
  List<Offset> _trackingPointers = [];
  double horizontalScale = 0.0;
  double verticalScale = 0.0;
  double scale = 0.0;
  bool _isDrawing = false;

  List<Offset> _points = [];
  double _minX = 0, _maxX = 0, _minY = 0, _maxY = 0;

  void _addPoint(Offset? point) {
    // Convert global pointer position to canvas-local position
    if (point != null) {
      final localPoint = _transformController.toScene(point);
      _points.add(localPoint);
    } else {
      _points.add(Offset.zero); // Add a null to create breaks in the drawing
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(onPointerDown: (event) {
      final localPoint = _transformController.toScene(event.localPosition);
      setState(() {
        _isDrawing = true;
        _addPoint(event.localPosition);
        widget.currentSketch.value = Sketch.fromDrawingMode(
            Sketch(
                vectors: [localPoint],
                size: widget.drawingMode.value == DrawingModes.eraser
                    ? widget.eraserSize.value
                    : widget.strokeSize.value,
                color: widget.drawingMode.value == DrawingModes.eraser
                    ? kCanvasColor
                    : widget.selectedColor.value,
                shapeSides: widget.shapeSides.value),
            widget.drawingMode.value,
            widget.filled.value);
        //widget.allSketches.value.add(widget.currentSketch.value!);

        _minX = _points.isEmpty
            ? localPoint.dx
            : _minX < localPoint.dx
                ? _minX
                : localPoint.dx;
        _maxX = _points.isEmpty
            ? localPoint.dx
            : _maxX > localPoint.dx
                ? _maxX
                : localPoint.dx;
        _minY = _points.isEmpty
            ? localPoint.dy
            : _minY < localPoint.dy
                ? _minY
                : localPoint.dy;
        _maxY = _points.isEmpty
            ? localPoint.dy
            : _maxY > localPoint.dy
                ? _maxY
                : localPoint.dy;
      });
    }, onPointerMove: (event) {
      if (_isDrawing) {
        final localPoint = _transformController.toScene(event.localPosition);
        setState(() {
          _addPoint(event.localPosition);
          final vectors =
              List<Offset>.from(widget.currentSketch.value?.vectors ?? [])
                ..add(localPoint);
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

          _minX = _points.isEmpty
              ? localPoint.dx
              : _minX < localPoint.dx
                  ? _minX
                  : localPoint.dx;
          _maxX = _points.isEmpty
              ? localPoint.dx
              : _maxX > localPoint.dx
                  ? _maxX
                  : localPoint.dx;
          _minY = _points.isEmpty
              ? localPoint.dy
              : _minY < localPoint.dy
                  ? _minY
                  : localPoint.dy;
          _maxY = _points.isEmpty
              ? localPoint.dy
              : _maxY > localPoint.dy
                  ? _maxY
                  : localPoint.dy;
        });
      }
    }, onPointerUp: (event) {
      setState(() {
        _isDrawing = false;
        _addPoint(null); // Add a break between lines
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
      });
    }, child: LayoutBuilder(builder: (context, constraints) {
      return InteractiveViewer(
          transformationController: _transformController,
          panEnabled: widget.drawingMode.value == DrawingModes.pan,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          minScale: 0.1,
          maxScale: 5.0,
          onInteractionUpdate: (details) {
            verticalScale = details.verticalScale;
            horizontalScale = details.horizontalScale;
            scale = details.scale;
            if (details.focalPoint.dx > canvasSizeNotifier.value.width - 100 ||
                details.focalPoint.dy > canvasSizeNotifier.value.height - 100) {
              canvasSizeNotifier.value = Size(
                canvasSizeNotifier.value.width + 1000,
                canvasSizeNotifier.value.height + 1000,
              );
            }
          },
          //NOTE: We still need to handle animation of the actual drawing to make it smooth.
          //NOTE: Nothing different from before we still need the canvas to grow and scale infinitely.
          child: SizedBox(
              width: (_maxX - _minX).abs() + 2000,
              height: (_maxY - _minY).abs() + 2000,
              child: CustomPaint(
                  painter: CanvasPainter(
                      points: _points, sketches: widget.allSketches.value),
                  size: Size.infinite))
          /*
        child: Container(
          //color: Colors.black,
          child: Stack(
            children: [
              buildAllSketches(context, verticalScale, scale),
              buildCurrentSketch(context, verticalScale, scale),
            ],
          ),
        ),
                    */
          );
    }));
  }

  void _handlePointerEvent(PointerEvent details) {
    final Offset localPosition =
        _transformController.toScene(details.localPosition);
    // Handle specific pointer events here
    if (details is PointerDownEvent) {
      _startDrawing(localPosition);
    } else if (details is PointerMoveEvent) {
      _updateDrawing(localPosition);
    } else if (details is PointerUpEvent) {
      _finishDrawing(localPosition);
    }

    setState(() {
      _trackingPointers.add(localPosition);
    });
  }

  void onPointerDown(PointerDownEvent details, BuildContext context) {
    //NOTE: Could renderbox be the issue why its stuck in small space?
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

  void _startDrawing(Offset position) {
    // Initialize a new sketch or drawing path
    widget.currentSketch.value = Sketch.fromDrawingMode(
        Sketch(
            vectors: [position],
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

  void _updateDrawing(Offset position) {
    // Update the current sketch with new points
    final vectors = List<Offset>.from(widget.currentSketch.value?.vectors ?? [])
      ..add(position);
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

  void _finishDrawing(Offset position) {
    // Finalize the current sketch and add it to the list of all sketches
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
  Widget buildAllSketches(
      BuildContext context, double scaleVertical, double scaleHorizontal) {
    return ValueListenableBuilder<List<Sketch>>(
      valueListenable: widget.allSketches,
      builder: (context, sketches, _) {
        return RepaintBoundary(
          key: widget.whiteboardCanvasKey,
          child: CustomPaint(
            size: Size.infinite,
            painter: SketchPainter(
                scaleVertical: scaleVertical,
                scaleHorizontal: scaleHorizontal,
                trackingPoints: _trackingPointers,
                canvasPos: widget.canvasPos.value,
                drawingMode: widget.drawingMode.value,
                sketches: sketches,
                bgImage: widget.backgroundImage.value),
          ),
        );
      },
    );
  }

//TODO: Refactor these smaller widgets somewhere else
  Widget buildCurrentSketch(
      BuildContext context, double scaleVertical, double scaleHorizontal) {
    return Listener(
      //TODO: Double Check this
      // onPointerDown: (details) => _startDrawing(details.localPosition),
      // onPointerMove: (details) => _updateDrawing(details.localPosition),
      // onPointerUp: (details) => _finishDrawing(details.localPosition),

      onPointerDown: (details) => onPointerDown(details, context),
      onPointerMove: (details) => onPointerMove(details, context),
      onPointerUp: onPointerUp,
      child: ValueListenableBuilder(
        valueListenable: widget.currentSketch,
        builder: (context, sketch, child) {
          return RepaintBoundary(
            child: CustomPaint(
              willChange: true,
              size: Size.infinite,
              painter: SketchPainter(
                scaleVertical: scaleVertical,
                scaleHorizontal: scaleHorizontal,
                trackingPoints: _trackingPointers,
                canvasPos: widget.canvasPos.value,
                drawingMode: widget.drawingMode.value,
                sketches: sketch == null ? [] : [sketch],
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
                    scaleVertical: 0.0,
                    scaleHorizontal: 0.0,
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
