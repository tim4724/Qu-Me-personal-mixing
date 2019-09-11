import 'dart:ui';

import 'package:flutter/material.dart';

class Send {
  final SendType sendType;
  final int id;
  String name;
  bool faderLinked;
  String personName;
  Color color;

  Send(this.sendType, this.id, this.name, this.faderLinked, [this.color]) {
    if (color == null) {
      // color by name
      color = Colors.black;
    }
  }

  bool get stereo => sendType == SendType.stereoChannel || faderLinked;

  @override
  String toString() {
    return 'Send{sendType: $sendType, id: $id, name: $name, faderLinked: $faderLinked}';
  }
}

enum SendType { monoChannel, stereoChannel, fxReturn, group }
