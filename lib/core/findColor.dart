import 'dart:ui';

const _colors = [
  Color(0xFF323232),
  Color.fromARGB(255, 222, 67, 31),
  Color.fromARGB(255, 67, 31, 222),
  Color(0xFFC9C9C9),
  Color.fromARGB(255, 196, 196, 196),
  Color.fromARGB(255, 210, 222, 31),
];

const _names = [
  ["drum", "kick", "snare", "tom", "hi-hat", "hihat", "crash", "ride"],
  ["git", "guit", "base", "bass", "cello"],
  ["key", "pad", "piano", "organ", "syn"],
  ["voc", "vox", "v"],
  ["click", "metr", "guide", "mic", "tb", "talk"],
];

/*
https://github.com/flutter/flutter/blob/master/examples/flutter_gallery/lib/demo/material/chip_demo.dart#L177
Maybe this is helpful
 */

Color findColor(String name) {

  for (int i = 0; i < _names.length; i++) {
    final nameList = _names[i];
    for (final n in nameList) {
      if (name.toLowerCase().contains(n)) {
        return _colors[i];
      }
    }
  }
  return _colors[name.hashCode % _colors.length];
}
