import 'dart:ui';

final _colors = [
  Color.fromARGB(255, 0, 0, 0),
  Color.fromARGB(255, 255, 0, 0),
  Color.fromARGB(255, 0, 0, 255),
  Color.fromARGB(255, 128, 128, 128),
];

final _names = [
  ["drum", "kick", "snare", "tom"],
  ["git", "guit", "base", "bass"],
  ["key", "pad", "piano", "organ", "syn"],
  ["voc", "vox", "v"],
];

Color findColor(String name) {
  // TODO: algorithm
  return _colors[name.hashCode % _colors.length];
}
