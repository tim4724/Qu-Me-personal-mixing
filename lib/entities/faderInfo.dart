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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FaderInfo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          displayId == other.displayId &&
          technicalName == other.technicalName &&
          name == other.name &&
          color == other.color &&
          personName == other.personName &&
          muteOn == other.muteOn;

  @override
  int get hashCode =>
      id.hashCode ^
      displayId.hashCode ^
      technicalName.hashCode ^
      name.hashCode ^
      color.hashCode ^
      personName.hashCode ^
      muteOn.hashCode;
}
