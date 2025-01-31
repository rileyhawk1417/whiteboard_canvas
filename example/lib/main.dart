import 'package:drawing_canvas/canvas/whiteboard.dart';
import 'package:drawing_canvas/drawing_canvas.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    var containedBoard = Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            //TODO: Ensure sized box constraint can be adjusted
            SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              height: MediaQuery.of(context).size.height / 2,
              child: DrawingCanvas().newWhiteBoard(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
    var pureBoard = Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: DrawingCanvas().newWhiteBoard(),
    );
    return pureBoard;
  }
}

class InfiniteCanvas extends StatefulWidget {
  @override
  _InfiniteCanvasState createState() => _InfiniteCanvasState();
}

class _InfiniteCanvasState extends State<InfiniteCanvas> {
  final TransformationController _transformationController =
      TransformationController();
  List<Offset> _points = [];

  bool _isDrawing = false; // To track if the user is drawing
  bool zoomEnabled = false;
  bool panEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Infinite Canvas (Desktop Supported)")),
      body: Listener(
        onPointerDown: (event) {
          setState(() {
            _isDrawing = true;
            _addPoint(event.localPosition);
          });
        },
        onPointerMove: (event) {
          if (_isDrawing) {
            setState(() {
              _addPoint(event.localPosition);
            });
          }
        },
        onPointerUp: (event) {
          setState(() {
            _isDrawing = false;
            _addPoint(null); // Add a break between lines
          });
        },
        child: InteractiveViewer(
          panEnabled: panEnabled,
          scaleEnabled: zoomEnabled,
          transformationController: _transformationController,
          boundaryMargin: EdgeInsets.all(
              double.infinity), // Allow panning beyond the boundaries
          minScale: 0.1, // Minimum zoom
          maxScale: 5.0, // Maximum zoom
          child: CustomPaint(
            painter: CanvasPainter(_points),
            size: Size.infinite, // Infinite size for canvas
          ),
        ),
      ),
      floatingActionButton:
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        FloatingActionButton(
          onPressed: () {
            setState(() {
              zoomEnabled = false;
              panEnabled = false;
              _isDrawing = true;
            });
          },
          child: Icon(Icons.draw),
        ),
        FloatingActionButton(
          onPressed: () {
            setState(() {
              panEnabled = false;
              zoomEnabled = true;
              _isDrawing = false;
            });
          },
          child: Icon(Icons.zoom_in),
        ),
        FloatingActionButton(
          onPressed: () {
            setState(() {
              panEnabled = true;
              zoomEnabled = false;
              _isDrawing = false;
            });
          },
          child: Icon(Icons.pan_tool),
        ),
        FloatingActionButton(
          onPressed: () {
            setState(() {
              _points.clear(); // Clear all points
            });
          },
          child: Icon(Icons.clear),
        )
      ]),
    );
  }

  void _addPoint(Offset? point) {
    // Convert global pointer position to canvas-local position
    if (point != null) {
      final localPoint = _transformationController.toScene(point);
      _points.add(localPoint);
    } else {
      _points.add(Offset.zero); // Add a null to create breaks in the drawing
    }
  }
}

class CanvasPainter extends CustomPainter {
  final List<Offset> points;

  CanvasPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    //final vectorPath = Path();
    /*
    for (var point in points) {
      if (points.isEmpty) return;
      // vectorPath.moveTo(points[0].dx, points[0].dy);
      // canvas.drawPath(vectorPath, paint);
      canvas.drawLine(point, points[points.length - 1], paint);
    }
        */

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i + 1]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CanvasPainter oldDelegate) {
    //return oldDelegate.points != points;
    return true;
  }
}
