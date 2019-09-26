import 'dart:ui';

import 'package:qu_me/core/findColor.dart';
import 'package:qu_me/entities/faderInfo.dart';

class Mix extends FaderInfo {
  final MixType mixType;
  // TODO make private
  final List<double> sendLevelsInDb;
  final List<bool> sendAssigns;

  factory Mix(int id, MixType type, int displayId, String name, bool muteOn,
      List<double> sendLevelsInDb, List<bool> sendAssigns) {
    String technicalName;
    if (type == MixType.mono) {
      technicalName = "Mix $displayId";
    } else {
      technicalName = "Mix $displayId/${displayId + 1}";
    }
    final color = findColor(name);
    final personName = "Tim";
    return Mix._internal(id, type, displayId, technicalName, name, color,
        personName, muteOn, sendLevelsInDb, sendAssigns);
  }

  Mix._internal(
      int id,
      this.mixType,
      int displayId,
      String technicalName,
      String name,
      Color color,
      String personName,
      bool muteOn,
      this.sendLevelsInDb,
      this.sendAssigns)
      : super(id, displayId, technicalName, name, color, personName, muteOn);

  @override
  bool get stereo => mixType == MixType.stereo;

  @override
  FaderInfo copyWith({
    String name,
    String personName,
    bool muteOn,
    List<double> sendLevelsInDb,
    List<bool> sendAssigns,
  }) {
    return Mix(
      this.id,
      this.mixType,
      this.displayId,
      name ?? this.name,
      muteOn ?? this.muteOn,
      sendLevelsInDb ?? this.sendLevelsInDb,
      sendAssigns ?? this.sendAssigns,
    );
  }
}

enum MixType { mono, stereo }
// TODO Group
