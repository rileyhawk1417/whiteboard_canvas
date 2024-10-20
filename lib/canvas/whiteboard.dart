import 'package:drawing_canvas/canvas/canvas.dart';
import 'package:drawing_canvas/canvas/models/drawing_modes.dart';
import 'package:drawing_canvas/canvas/models/sketch_model.dart';
import 'package:drawing_canvas/canvas/widgets/toolbar.dart';
import 'package:flutter/material.dart' hide Image;
import 'dart:ui';
import 'package:flutter_hooks/flutter_hooks.dart';

class Whiteboard extends HookWidget {
  const Whiteboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final whiteboardCanvasKey = GlobalKey();
    final eraserSize = useState<double>(30);
    final selectedColor = useState(Colors.black);
    final drawingMode = useState(DrawingModes.pencil);
    final filled = useState<bool>(false);
    final shapeSides = useState<int>(3);
    final strokeSize = useState<double>(30);
    final backgroundImage = useState<Image?>(null);
    ValueNotifier<Sketch?> currentSketch = useState(null);
    ValueNotifier<List<Sketch>> allSketches = useState([]);
    ValueNotifier<Offset> canvasPos = useState(Offset.zero);
    ValueNotifier<Offset> startPos = useState(Offset.zero);

    final animationController = useAnimationController(
        duration: const Duration(milliseconds: 150), initialValue: 1);

    return Scaffold(
      body: Stack(
        //NOTE: Due to alignment issue bar will stay fixed. Maybe allow custom positioning?
        alignment: AlignmentDirectional.bottomCenter,
        children: [
          Container(
            color: kCanvasColor,
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: WhiteboardCanvas(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              eraserSize: eraserSize,
              selectedColor: selectedColor,
              drawingMode: drawingMode,
              currentSketch: currentSketch,
              allSketches: allSketches,
              whiteboardCanvasKey: whiteboardCanvasKey,
              filled: filled,
              shapeSides: shapeSides,
              strokeSize: strokeSize,
              sideBarController: animationController,
              backgroundImage: backgroundImage,
              canvasPos: canvasPos,
              startPos: startPos,
            ),
          ),
          CanvasToolBar(
              selectedColor: selectedColor,
              strokeSize: strokeSize,
              eraserSize: eraserSize,
              drawingMode: drawingMode,
              currentSketch: currentSketch,
              allSketches: allSketches,
              canvasGlobalKey: whiteboardCanvasKey,
              filled: filled,
              shapeSides: shapeSides,
              backgroundImage: backgroundImage)
        ],
      ),
    );
  }
}
