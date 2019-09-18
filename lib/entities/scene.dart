import 'package:qu_me/entities/mix.dart';
import 'package:qu_me/entities/send.dart';

class Scene {
  final List<Send> sends;
  final List<Mix> mixes;

  Scene(this.sends, this.mixes);

  @override
  String toString() {
    return 'Scene{sends: $sends, mixes: $mixes}';
  }
}

Scene buildDemoScene() {
  // TODO fix ids, names,
  final sends = List<Send>();
  for (int i = 0; i < 32; i++) {
    sends.add(Send(i, SendType.monoChannel, i + 1, "Demo${i + 1}", false));
  }
  for (int i = 0; i < 3; i++) {
    sends.add(
        Send(i + 32, SendType.stereoChannel, i + 1, "Stereo${i + 1}", false));
  }
  for (int i = 0; i < 4; i++) {
    sends.add(Send(i + 35, SendType.stereoChannel, i + 1, "FX${i + 1}", false));
  }
  final mixes = [
    Mix(1, MixType.mono, 0x27, "Voc 1", List.filled(39, 0)),
    Mix(2, MixType.mono, 0x28, "Voc 2", List.filled(39, 0)),
    Mix(3, MixType.mono, 0x29, "Voc 3", List.filled(39, 0)),
    Mix(4, MixType.mono, 0x2A, "Voc 4", List.filled(39, 0)),
    Mix(5, MixType.stereo, 0x2B, "Key", List.filled(39, 0)),
    Mix(7, MixType.stereo, 0x2C, "Bass", List.filled(39, 0)),
    Mix(9, MixType.stereo, 0x2D, "Drum", List.filled(39, 0)),
  ];
  return Scene(sends, mixes);
}
