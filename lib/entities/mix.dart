import 'dart:ui';

import 'package:qu_me/entities/controlGroup.dart';
import 'package:qu_me/entities/faderInfo.dart';

class Mix extends FaderInfo {
  final MixType mixType;

  Mix.empty() : this(-1, null, -1, "", "", false, {});

  Mix(
    int id,
    this.mixType,
    int displayId,
    String name,
    String personName,
    bool explicitMuteOn,
    Set<ControlGroup> controlGroups,
  ) : super(
          id,
          displayId,
          _technicalName(mixType, displayId),
          name,
          personName,
          explicitMuteOn,
          controlGroups,
        );

  @override
  bool get stereo => mixType == MixType.stereo;

  static String _technicalName(MixType type, int displayId) {
    if (type == MixType.mono) {
      return "Mix $displayId";
    }
    if (type == MixType.stereo) {
      return "Mix $displayId/${displayId + 1}";
    }
    return "";
  }

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
      personName ?? this.personName,
      explicitMuteOn ?? this.explicitMuteOn,
      controlGroups ?? this.controlGroups,
    );
  }
}

enum MixType { mono, stereo }
// TODO Group
