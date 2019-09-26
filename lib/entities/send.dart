import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:qu_me/core/findColor.dart';
import 'package:qu_me/entities/faderInfo.dart';

class Send extends FaderInfo {
  final SendType sendType;
  final bool faderLinked;
  final bool panLinked;

  Send._internal(
      int id,
      this.sendType,
      int displayId,
      String technicalName,
      String name,
      Color color,
      String personName,
      this.faderLinked,
      this.panLinked,
      bool muteOn)
      : super(id, displayId, technicalName, name, color, personName, muteOn);

  factory Send(int id, SendType type, int displayId, String name,
      bool faderLinked, bool panLinked, bool muteOn) {
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
    final color = findColor(name);
    final personName = "Tim";
    return Send._internal(id, type, displayId, technicalName, name, color,
        personName, faderLinked, panLinked, muteOn);
  }

  @override
  bool get stereo => sendType == SendType.stereoChannel;

  @override
  FaderInfo copyWith({
    String name,
    String personName,
    bool muteOn,
    bool faderLinked,
    bool panLinked,
  }) {
    return Send(
      this.id,
      this.sendType,
      this.displayId,
      name ?? this.name,
      faderLinked ?? this.faderLinked,
      panLinked ?? this.panLinked,
      muteOn == this.muteOn,
    );
  }
}

enum SendType { monoChannel, stereoChannel, fxReturn, group }
