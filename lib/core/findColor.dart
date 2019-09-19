import 'dart:ui';

const _colors = [
  Color.fromARGB(255, 0, 0, 0),
  Color.fromARGB(255, 222, 67, 31),
  Color.fromARGB(255, 67, 31, 222),
  Color.fromARGB(255, 196, 196, 196),
];

const _names = [
  ["drum", "kick", "snare", "tom", "hi-hat", "hihat", "crash", "ride"],
  ["git", "guit", "base", "bass", "cello"],
  ["key", "pad", "piano", "organ", "syn"],
  ["voc", "vox", "v"],
];

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
