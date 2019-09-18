import 'dart:ui';

import 'package:qu_me/core/findColor.dart';

class Mix {
  final int id;
  final MixType mixType;
  final int displayId;
  final sendValues;
  String _technicalName;
  String name;
  String personName;
  Color color;

  Mix(this.id, this.mixType, this.displayId, this.name, this.sendValues) {
    if (mixType == MixType.mono) {
      _technicalName = "Mix $displayId";
    } else {
      _technicalName = "Mix $displayId/${displayId + 1}";
    }
    personName = "Tom";
    color = findColor(name);
  }

  bool get stereo => mixType == MixType.stereo;

  String get technicalName => _technicalName;

  @override
  String toString() {
    return 'Mix{id: $id, mixType: $mixType, displayId: $displayId, sendValues: $sendValues, _technicalName: $_technicalName, name: $name, personName: $personName}';
  }
}

enum MixType { mono, stereo }
// TODO Group
