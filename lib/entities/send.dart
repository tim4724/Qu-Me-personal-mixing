import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:qu_me/core/findColor.dart';

class Send {
  final int id;
  final SendType sendType;
  final displayId;
  String _technicalName;
  String _name;
  bool faderLinked;
  bool panLinked;
  String _personName;
  Color color;

  Send(this.id, this.sendType, this.displayId, this._name, this.faderLinked,
      this.panLinked) {
    color = findColor(_name);
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
  }

  bool get stereo => sendType == SendType.stereoChannel;

  String get technicalName => _technicalName;

  String get personName {
    if (_personName != null && _personName.isNotEmpty) {
      return personName;
    }
    return technicalName;
  }

  String get name => _name;

  void set name(String name) {
    _name = name;
    color = findColor(name);
  }

  @override
  String toString() {
    return 'Send{id: $id, sendType: $sendType, displayId: $displayId, '
        '_technicalName: $_technicalName, name: $name, faderLinked: $faderLinked, '
        'personName: $personName, color: $color}';
  }
}

enum SendType { monoChannel, stereoChannel, fxReturn, group }
