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
  // TODO fix ids, names,
  final sends = List<Send>();
  for (int i = 0; i < 32; i++) {
    sends.add(Send(i, SendType.monoChannel, i + 1, "Demo${i + 1}", false, false));
  }
  sends[0].name = "Kick";
  sends[1].name = "Snare";
  sends[2].name = "Drum L";
  sends[3].name = "Drum R";
  sends[4].name = "Bass";
  sends[5].name = "Git";
  sends[6].name = "E-Git";
  sends[7].name = "Cello";
  sends[8].name = "Keys";
  sends[9].name = "Pads";
  sends[10].name = "Synth";
  sends[11].name = "Voc 1";
  sends[12].name = "Voc 2";
  sends[13].name = "Voc 3";
  sends[14].name = "Voc 4";
  for (int i = 0; i < 3; i++) {
    sends.add(
        Send(i + 32, SendType.stereoChannel, i + 1, "Stereo${i + 1}", false, false));
  }
  for (int i = 0; i < 4; i++) {
    sends.add(Send(i + 35, SendType.stereoChannel, i + 1, "FX${i + 1}", false, false));
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
