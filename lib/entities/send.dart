import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:qu_me/core/findColor.dart';

class Send {
  final int id;
  final SendType sendType;
  final displayId;
  String _technicalName;
  String name;
  bool faderLinked;
  bool panLinked;
  String personName;
  Color color;

  Send(this.id, this.sendType, this.displayId, this.name, this.faderLinked,
      this.panLinked) {
    color = findColor(name);
    switch (sendType) {
      case SendType.monoChannel:
        _technicalName = "Ch $displayId";
        break;
      case SendType.stereoChannel:
        _technicalName = "St $displayId";
        break;
      case SendType.fxReturn:
        _technicalName = "FxRet $displayId";
        break;
      case SendType.group:
        _technicalName = "Grp $displayId";
        break;
      default:
        _technicalName = "$displayId";
        break;
    }
    personName = "Tom";
  }

  bool get stereo => sendType == SendType.stereoChannel;

  String get technicalName => _technicalName;

  @override
  String toString() {
    return 'Send{id: $id, sendType: $sendType, displayId: $displayId, _technicalName: $_technicalName, name: $name, faderLinked: $faderLinked, personName: $personName, color: $color}';
  }
}

enum SendType { monoChannel, stereoChannel, fxReturn, group }
