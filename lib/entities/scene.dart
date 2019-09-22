import 'package:qu_me/entities/mix.dart';
import 'package:qu_me/entities/send.dart';

class Scene {
  final List<Send> sends;
  final List<Mix> mixes;
  final List<double> mixesLevelInDb;

  Scene(this.sends, this.mixes, this.mixesLevelInDb);

  @override
  String toString() {
    return 'Scene{sends: $sends, mixes: $mixes}';
  }
}

Scene buildDemoScene() {
  final names = [
    "Kick",
    "Snare",
    "Drums L",
    "Drums R",
    "Bass",
    "",
    "E-Git",
    "Git",
    "Keys L",
    "Keys R",
    "Pads",
    "Synth",
    "Voc 1",
    "Voc 2",
    "Voc 3",
    "Voc 4",
    "Mic 1",
    "Mic 2"
  ];
  final sends = List<Send>();
  for (int i = 0; i < 32; i++) {
    final name = i < names.length ? names[i] : "CH ${i + 1}";
    sends.add(Send(i, SendType.monoChannel, i + 1, name,
        name.startsWith("Drums") || name.startsWith("Keys"), false));
  }
  final stereoNames = ["PC", "Handy", "Atmo"];
  for (int i = 0; i < 3; i++) {
    final name = i < stereoNames.length ? stereoNames[i] : "St ${i + 1}";
    sends.add(Send(i + 32, SendType.stereoChannel, i + 1, name, false, false));
  }
  final fxNames = ["voc", "instr"];
  for (int i = 0; i < 4; i++) {
    final name = i < fxNames.length ? fxNames[i] : "FX ${i + 1}";
    sends.add(Send(i + 35, SendType.fxReturn, i + 1, name, false, false));
  }
  final mixes = [
    Mix(0x27, MixType.mono, 1, "Voc 1", List.filled(39, -128.0)),
    Mix(0x28, MixType.mono, 2, "Voc 2", List.filled(39, -128.0)),
    Mix(0x29, MixType.mono, 3, "Voc 3", List.filled(39, -128.0)),
    Mix(0x2A, MixType.mono, 4, "Voc 4", List.filled(39, -128.0)),
    Mix(0x2B, MixType.stereo, 5, "Key", List.filled(39, -128.0)),
    Mix(0x2C, MixType.stereo, 7, "Bass", List.filled(39, -128.0)),
    Mix(0x2D, MixType.stereo, 9, "Drum", List.filled(39, -128.0)),
  ];
  return Scene(sends, mixes, List.filled(7, -128.0));
}
