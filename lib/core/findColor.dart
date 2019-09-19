import 'dart:ui';

const _colors = [
  Color.fromARGB(255, 0, 0, 0),
  Color.fromARGB(255, 222, 67, 31),
  Color.fromARGB(255, 67, 31, 222),
  Color.fromARGB(255, 196, 196, 196),
];

const _names = [
  ["drum", "kick", "snare", "tom"],
  ["git", "guit", "base", "bass"],
  ["key", "pad", "piano", "organ", "syn"],
  ["voc", "vox", "v"],
];

Color findColor(String name) {
  // TODO: algorithm
  return _colors[name.hashCode % _colors.length];
}
