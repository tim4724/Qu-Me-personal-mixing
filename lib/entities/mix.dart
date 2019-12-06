import 'dart:ui';

import 'package:qu_me/core/findColor.dart';
import 'package:qu_me/entities/controlGroup.dart';
import 'package:qu_me/entities/faderInfo.dart';

class Mix extends FaderInfo {
  final MixType mixType;

  factory Mix.empty() {
    return Mix._internal(
        -1, null, 0, "", "", Color(0xFF888888), "", false, {});
  }

  factory Mix(int id, MixType type, int displayId, String name,
      bool explicitMuteOn, Set<ControlGroup> controlGroups) {
    String technicalName;
    if (type == MixType.mono) {
      technicalName = "Mix $displayId";
    } else {
      technicalName = "Mix $displayId/${displayId + 1}";
    }
    final color = findColor(name);
    final personName = null;
    return Mix._internal(
      id,
      type,
      displayId,
      technicalName,
      name,
      color,
      personName,
      explicitMuteOn,
      controlGroups,
    );
  }

  Mix._internal(
    int id,
    this.mixType,
    int displayId,
    String technicalName,
    String name,
    Color color,
    String personName,
    bool explicitMuteOn,
    Set<ControlGroup> controlGroups,
  ) : super(id, displayId, technicalName, name, color, personName,
            explicitMuteOn, controlGroups);

  @override
  bool get stereo => mixType == MixType.stereo;

  @override
  FaderInfo copyWith({
    String name,
    String personName,
    Color color,
    bool explicitMuteOn,
    Set<ControlGroup> controlGroups,
  }) {
    return Mix(
      this.id,
      this.mixType,
      this.displayId,
      name ?? this.name,
      explicitMuteOn ?? this.explicitMuteOn,
      controlGroups ?? this.controlGroups,
    );
  }
}

enum MixType { mono, stereo }
// TODO Group
