import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:qu_me/core/findColor.dart';
import 'package:qu_me/entities/controlGroup.dart';
import 'package:qu_me/entities/faderInfo.dart';

class Send extends FaderInfo {
  final SendType sendType;

  Send._internal(
    int id,
    this.sendType,
    int displayId,
    String technicalName,
    String name,
    Color color,
    String personName,
    bool explicitMuteOn,
    Set<ControlGroup> controlGroups,
  ) : super(id, displayId, technicalName, name, color, personName,
            explicitMuteOn, controlGroups);

  factory Send(
    int id,
    SendType type,
    int displayId,
    String name,
    bool explicitMuteOn,
    Set<ControlGroup> controlGroups,
  ) {
    String technicalName;
    switch (type) {
      case SendType.monoChannel:
        technicalName = "Ch $displayId";
        break;
      case SendType.stereoChannel:
        technicalName = "St $displayId";
        break;
      case SendType.fxReturn:
        technicalName = "FxRet $displayId";
        break;
      case SendType.group:
        technicalName = "Grp $displayId";
        break;
      default:
        technicalName = "$displayId";
        break;
    }
    final color = findColorForSend(name, type);
    final personName = null;
    return Send._internal(id, type, displayId, technicalName, name, color,
        personName, explicitMuteOn, controlGroups);
  }

  @override
  bool get stereo => sendType == SendType.stereoChannel;

  @override
  FaderInfo copyWith({
    String name,
    String personName,
    bool explicitMuteOn,
    Set<ControlGroup> controlGroups,
  }) {
    return Send(
        this.id,
        this.sendType,
        this.displayId,
        name ?? this.name,
        explicitMuteOn ?? this.explicitMuteOn,
        controlGroups ?? this.controlGroups);
  }
}

enum SendType { monoChannel, stereoChannel, fxReturn, group }
