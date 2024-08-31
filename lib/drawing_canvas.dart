library drawing_canvas;

import 'package:drawing_canvas/canvas/whiteboard.dart';

/*
NOTE: The plan is to have a drawing class.
- A class that can handle vectors & positioning.
- A class to handle color specifically.
- A class for shapes.
- A class to handle backgrond images.
- A class for drawing tools (pencils, eraser, etc)
*/
/// DrawingCanvas
class DrawingCanvas {
  newWhiteBoard() {
    return const Whiteboard();
  }
}
