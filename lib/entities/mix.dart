import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:qu_me/core/findColor.dart';
import 'package:qu_me/entities/controlGroup.dart';
import 'package:qu_me/entities/faderInfo.dart';
import 'package:qu_me/util.dart';

class Mix extends FaderInfo {
  final MixType mixType;
  final UnmodifiableListView<double> sendLevelsInDb;
  final UnmodifiableListView<int> sendPans;
  final UnmodifiableListView<bool> sendAssigns;

  factory Mix(
    int id,
    MixType type,
    int displayId,
    String name,
    bool explicitMuteOn,
    Set<ControlGroup> controlGroups,
    List<double> sendLevelsInDb,
    List<int> sendPans,
    List<bool> sendAssigns,
  ) {
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
      unmodifiableList(sendLevelsInDb),
      unmodifiableList(sendPans),
      unmodifiableList(sendAssigns),
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
    this.sendLevelsInDb,
    this.sendPans,
    this.sendAssigns,
  ) : super(id, displayId, technicalName, name, color, personName,
            explicitMuteOn, controlGroups);

  @override
  bool get stereo => mixType == MixType.stereo;

  @override
  FaderInfo copyWith({
    String name,
    String personName,
    bool explicitMuteOn,
    Set<ControlGroup> controlGroups,
    List<double> sendLevelsInDb,
    List<int> sendPans,
    List<bool> sendAssigns,
  }) {
    return Mix(
      this.id,
      this.mixType,
      this.displayId,
      name ?? this.name,
      explicitMuteOn ?? this.explicitMuteOn,
      controlGroups ?? this.controlGroups,
      sendLevelsInDb ?? this.sendLevelsInDb,
      sendPans ?? this.sendPans,
      sendAssigns ?? this.sendAssigns,
    );
  }
}

enum MixType { mono, stereo }
// TODO Group
