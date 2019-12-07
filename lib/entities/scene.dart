import 'package:qu_me/entities/controlGroup.dart';
import 'package:qu_me/entities/mix.dart';
import 'package:qu_me/entities/send.dart';

class Scene {
  final List<ControlGroup> controlGroups = List<ControlGroup>(8);
  final List<Send> sends = List<Send>(39);
  final List<bool> sendsLevelLinked = List.filled(32, false);
  final List<bool> sendsPanLinked = List.filled(32, false);
  final List<Mix> mixes = List<Mix>(7);
  final List<double> mixesLevelInDb = List.filled(7, -128.0);
  final List<bool> sendAssigns = List.filled(39, false);
  final List<double> sendLevelsInDb = List.filled(39, -128.0);
  final List<int> sendPans = List.filled(32, 37);
}

Scene buildDemoScene(int mixId) {
  final scene = Scene();

  final controlGroups = List<ControlGroup>.generate(
      8,
      (i) => ControlGroup(i < 4 ? i : i - 4,
          i < 4 ? ControlGroupType.dca : ControlGroupType.muteGroup, false));
  scene.controlGroups.setRange(0, 8, controlGroups);

  final names = [
    "Kick",
    "Snare",
    "Drum L",
    "Drum R",
    "Bass",
    "",
    "E-Git",
    "Git",
    "Key L",
    "Key R",
    "Pad",
    "Synth",
    "Voc 1",
    "Voc 2",
    "Voc 3",
    "Voc 4",
    "Mic 1",
    "Mic 2"
  ];

  for (int i = 0; i < 32; i++) {
    final name = i < names.length ? names[i] : "CH ${i + 1}";
    final link = name.startsWith("Drum") || name.startsWith("Key");
    scene.sendsLevelLinked[i] = link;
    scene.sendsPanLinked[i] = link;
    scene.sends[i] = Send(
        i, SendType.monoChannel, i + 1, name, null, false, Set<ControlGroup>());
  }
  final stereoNames = ["PC", "Smartphone", "Atmo"];
  for (int i = 0; i < 3; i++) {
    final name = i < stereoNames.length ? stereoNames[i] : "St ${i + 1}";
    scene.sends[i + 32] = Send(i + 32, SendType.stereoChannel, i + 1, name,
        null, i < 2, Set<ControlGroup>());
  }
  final fxNames = ["voc", "instr"];
  for (int i = 0; i < 4; i++) {
    final name = i < fxNames.length ? fxNames[i] : "";
    scene.sends[i + 35] = Send(i + 35, SendType.fxReturn, i + 1, name, null,
        false, Set<ControlGroup>());
  }
  if (mixId != null && mixId != -1) {
    scene.sendAssigns.fillRange(0, scene.sendAssigns.length, true);
  }

  scene.mixes.setRange(0, 7, [
    Mix(0x27, MixType.mono, 1, "Voc 1", null, false, Set<ControlGroup>()),
    Mix(0x28, MixType.mono, 2, "Voc 2", null, false, Set<ControlGroup>()),
    Mix(0x29, MixType.mono, 3, "Voc 3", null, false, Set<ControlGroup>()),
    Mix(0x2A, MixType.mono, 4, "Voc 4", null, false, Set<ControlGroup>()),
    Mix(0x2B, MixType.stereo, 5, "Key", null, false, Set<ControlGroup>()),
    Mix(0x2C, MixType.stereo, 7, "Bass", null, false, Set<ControlGroup>()),
    Mix(0x2D, MixType.stereo, 9, "Drum", null, false, Set<ControlGroup>()),
  ]);
  return scene;
}
