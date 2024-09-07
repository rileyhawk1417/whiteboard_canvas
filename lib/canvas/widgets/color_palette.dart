import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

//TODO: Import flutter_svg, flutter_colorpicker
//NOTE: Possibly allow customization for row/column for toolbar.
class ColorPalette extends HookWidget {
  final ValueNotifier<Color> selectedColor;

  const ColorPalette({Key? key, required this.selectedColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ValueNotifier<Color> lastSelectedColor = selectedColor;
    List<Color> colors = [
      Colors.black,
      Colors.white,
      //...Colors.primaries,
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 2,
          runSpacing: 2,
          children: [
            for (Color color in colors)
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => selectedColor.value = color,
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(
                          color: selectedColor.value == color
                              ? Colors.blue
                              : Colors.grey,
                          width: 1.5),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(5),
                      ),
                    ),
                  ),
                ),
              )
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        //NOTE: This is the recently used color swatch. Figure out a way to store it in state.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            /*
            Container(
              height: 30,
              width: 30,
              decoration: BoxDecoration(
                color: lastSelectedColor.value,
                border: Border.all(color: Colors.blue, width: 1.5),
                borderRadius: const BorderRadius.all(
                  Radius.circular(5),
                ),
              ),
            ),
                        */
            const SizedBox(
              width: 10,
            ),
            MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                    onTap: () {
                      showColorWheel(context, selectedColor);
                      lastSelectedColor.value = selectedColor.value;
                    },
                    //TODO: Replace with color picker svg image
                    child: const Icon(Icons.color_lens)))
          ],
        )
      ],
    );
  }
}

void showColorWheel(BuildContext context, ValueNotifier<Color> color) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: color.value,
              onColorChanged: (value) {
                color.value = value;
              },
            ),
          ),
          actions: [
            TextButton(
                child: const Text('Done'),
                onPressed: () => Navigator.pop(context))
          ],
        );
      });
}
