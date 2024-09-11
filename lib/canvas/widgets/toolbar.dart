import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:drawing_canvas/canvas/models/drawing_modes.dart';
import 'package:drawing_canvas/canvas/models/sketch_model.dart';
import 'package:drawing_canvas/canvas/widgets/color_palette.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CanvasToolBar extends HookWidget {
  final ValueNotifier<Color> selectedColor;
  final ValueNotifier<double> strokeSize;
  final ValueNotifier<double> eraserSize;
  final ValueNotifier<DrawingModes> drawingMode;
  final ValueNotifier<Sketch?> currentSketch;
  final ValueNotifier<List<Sketch>> allSketches;
  final GlobalKey canvasGlobalKey;
  final ValueNotifier<bool> filled;
  final ValueNotifier<int> shapeSides;
  final ValueNotifier<ui.Image?> backgroundImage;

  const CanvasToolBar(
      {Key? key,
      required this.selectedColor,
      required this.strokeSize,
      required this.eraserSize,
      required this.drawingMode,
      required this.currentSketch,
      required this.allSketches,
      required this.canvasGlobalKey,
      required this.filled,
      required this.shapeSides,
      required this.backgroundImage})
      : super(key: key);
  //TODO: build undo/redo tree and shape icons
  @override
  Widget build(BuildContext context) {
    final _undoRedoStack = useState(_UndoRedoStack(
        sketchesNotifier: allSketches, currentSketchNotifier: currentSketch));
    final scrollController = useScrollController();

    return Container(
      //NOTE: Enable custom height sizing...
      width: MediaQuery.of(context).size.width < 680 ? 300 : 600,
      height: MediaQuery.of(context).size.height < 680 ? 80 : 120,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              const BorderRadius.horizontal(right: Radius.circular(10)),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 3,
                offset: const Offset(3, 3))
          ]),
      child: Scrollbar(
        scrollbarOrientation: ScrollbarOrientation.bottom,
        controller: scrollController,
        thumbVisibility: true,
        trackVisibility: true,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(10.0),
          controller: scrollController,
          children: [
            Column(children: [
              const SizedBox(height: 10),
              const Text('Shapes',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              Wrap(
                alignment: WrapAlignment.start,
                spacing: 5,
                runSpacing: 5,
                children: [
                  _IconBox(
                      iconData: Icons.edit,
                      selected: drawingMode.value == DrawingModes.pencil,
                      onTap: () => drawingMode.value = DrawingModes.pencil,
                      onLongPress: () => {},
                      onSecondaryTap: () => showOptions(
                          context, eraserSize, strokeSize, selectedColor),
                      tooltip: 'Pencil'),
                  _IconBox(
                    selected: drawingMode.value == DrawingModes.line,
                    onTap: () => drawingMode.value = DrawingModes.line,
                    tooltip: 'Line',
                    onLongPress: () => {},
                    onSecondaryTap: () => {},
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                            width: 22,
                            height: 2,
                            color: drawingMode.value == DrawingModes.line
                                ? Colors.grey[900]
                                : Colors.grey)
                      ],
                    ),
                  ),
                  //TODO: Add polygon size changer later
                  _IconBox(
                      iconData: Icons.hexagon_outlined,
                      selected: drawingMode.value == DrawingModes.polygon,
                      onTap: () => drawingMode.value = DrawingModes.polygon,
                      onLongPress: () => {},
                      onSecondaryTap: () => {},
                      tooltip: 'Polygon'),
                  //NOTE: Change the icon for the eraser...
                  _IconBox(
                      iconData: FontAwesomeIcons.eraser,
                      selected: drawingMode.value == DrawingModes.eraser,
                      onTap: () => drawingMode.value = DrawingModes.eraser,
                      onLongPress: () => {},
                      onSecondaryTap: () => {},
                      tooltip: 'Eraser'),
                  _IconBox(
                      iconData: Icons.square,
                      selected: drawingMode.value == DrawingModes.square,
                      onTap: () => drawingMode.value = DrawingModes.square,
                      onLongPress: () => {},
                      onSecondaryTap: () => {},
                      tooltip: 'Square'),

                  _IconBox(
                      iconData: Icons.circle,
                      selected: drawingMode.value == DrawingModes.circle,
                      onTap: () => drawingMode.value = DrawingModes.circle,
                      onLongPress: () => {},
                      onSecondaryTap: () => {},
                      tooltip: 'Circle'),
                  _IconBox(
                      iconData: Icons.pan_tool,
                      selected: drawingMode.value == DrawingModes.pan,
                      onTap: () => drawingMode.value = DrawingModes.pan,
                      onLongPress: () => {},
                      onSecondaryTap: () => {},
                      tooltip: 'Pan')
                ],
              )
            ]),
            const SizedBox(width: 10),
            Column(children: [
              const SizedBox(height: 10),
              const Text('Color',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ColorPalette(selectedColor: selectedColor)
            ]),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData? iconData;
  final Widget? child;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onSecondaryTap;
  final String? tooltip;

  const _IconBox(
      {Key? key,
      this.iconData,
      this.child,
      this.tooltip,
      required this.selected,
      required this.onLongPress,
      required this.onSecondaryTap,
      required this.onTap})
      : assert(child != null || iconData != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onLongPress: onLongPress,
        onSecondaryTap: onSecondaryTap,
        onTap: onTap,
        child: Container(
          height: 35,
          width: 35,
          decoration: BoxDecoration(
            border: Border.all(
                color: selected ? Colors.grey[900]! : Colors.grey, width: 1.5),
            borderRadius: const BorderRadius.all(Radius.circular(5)),
          ),
          child: Tooltip(
            message: tooltip,
            preferBelow: false,
            child: child ??
                Icon(
                  iconData,
                  color: selected ? Colors.grey[900] : Colors.grey,
                  size: 20,
                ),
          ),
        ),
      ),
    );
  }
}

void showOptions(BuildContext context, ValueNotifier<double> eraserSize,
    ValueNotifier<double> strokeSize, ValueNotifier<Color> color) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return OptionDialog(
            eraserSize: eraserSize, strokeSize: strokeSize, color: color);
      });
}

class OptionDialog extends StatefulWidget {
  const OptionDialog(
      {required this.eraserSize,
      required this.strokeSize,
      required this.color});
  final ValueNotifier<double> eraserSize;
  final ValueNotifier<double> strokeSize;
  final ValueNotifier<Color> color;
  @override
  OptionDialogState createState() => OptionDialogState();
}

class OptionDialogState extends State<OptionDialog> {
  @override
  Widget build(BuildContext context) {
    double eraserSize = widget.eraserSize.value;
    double strokeSize = widget.strokeSize.value;
    Color color = widget.color.value;
    return AlertDialog(
      title: const Text('Customize'),
      content: Column(
        children: [
          Text('Choose a color', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(
              child: ColorPicker(
            pickerColor: color,
            onColorChanged: (value) {
              setState(() {
                widget.color.value = value;
              });
            },
          )),
          Column(children: [
            const SizedBox(height: 10),
            const Text('Stroke Size',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Slider(
                value: strokeSize,
                min: 0,
                max: 50,
                onChanged: (val) {
                  setState(() {
                    widget.strokeSize.value = val;
                  });
                }),
          ]),
          Column(
            children: [
              const SizedBox(height: 10),
              const Text('Eraser Size',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                  value: eraserSize,
                  min: 0,
                  max: 80,
                  onChanged: (val) {
                    setState(() {
                      widget.eraserSize.value = val;
                    });
                  })
            ],
          )
        ],
      ),
      actions: [
        MaterialButton(
            child: Text('Done'), onPressed: () => Navigator.pop(context))
      ],
    );
  }
}

class _UndoRedoStack {
  _UndoRedoStack(
      {required this.sketchesNotifier, required this.currentSketchNotifier}) {
    _sketchCount = sketchesNotifier.value.length;
    sketchesNotifier.addListener(_sketchesCountListener);
  }

  final ValueNotifier<List<Sketch>> sketchesNotifier;
  final ValueNotifier<Sketch?> currentSketchNotifier;

  late final List<Sketch> _redoStack = [];

  ValueNotifier<bool> get canRedo => _canRedo;
  late final ValueNotifier<bool> _canRedo = ValueNotifier(false);
  late int _sketchCount;

  void _sketchesCountListener() {
    if (sketchesNotifier.value.length > _sketchCount) {
      _redoStack.clear();
      _canRedo.value = false;
      _sketchCount = sketchesNotifier.value.length;
    }
  }

  void clear() {
    _sketchCount = 0;
    sketchesNotifier.value = [];
    _canRedo.value = false;
    currentSketchNotifier.value = null;
  }

  void undo() {
    final sketches = List<Sketch>.from(sketchesNotifier.value);
    if (sketches.isNotEmpty) {
      _sketchCount--;
      _redoStack.add(sketches.removeLast());
      sketchesNotifier.value = sketches;
      _canRedo.value = true;
      currentSketchNotifier.value = null;
    }
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final sketch = _redoStack.removeLast();
    _canRedo.value = _redoStack.isNotEmpty;
    _sketchCount++;
    sketchesNotifier.value = [...sketchesNotifier.value, sketch];
  }

  void dispose() {
    sketchesNotifier.removeListener(_sketchesCountListener);
  }
}
