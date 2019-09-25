import 'dart:ui';

import 'package:qu_me/core/findColor.dart';
import 'package:qu_me/entities/faderInfo.dart';

class Mix extends FaderInfo {
  // TODO make private
  final MixType mixType;
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
  bool operator ==(Object other) =>
      identical(this, other) ||
          super == other &&
              other is Mix &&
              runtimeType == other.runtimeType &&
              mixType == other.mixType &&
              sendLevelsInDb == other.sendLevelsInDb &&
              sendAssigns == other.sendAssigns;

  @override
  int get hashCode =>
      super.hashCode ^
      mixType.hashCode ^
      sendLevelsInDb.hashCode ^
      sendAssigns.hashCode;



}

enum MixType { mono, stereo }
// TODO Group
