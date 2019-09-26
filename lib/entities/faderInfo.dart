import 'package:flutter/widgets.dart';

abstract class FaderInfo {
  final int id; // global id
  final int displayId; // not user defined id for send
  final String technicalName; // not user defined name for send
  final String name; // user defined name
  final Color color;
  final String personName; // name of the musician
  final bool muteOn;

  FaderInfo(this.id, this.displayId, this.technicalName, this.name, this.color,
      this.personName, this.muteOn);

  bool get stereo;

  FaderInfo copyWith({String name, String personName, bool muteOn});
}
