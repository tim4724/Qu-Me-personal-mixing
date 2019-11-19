import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:qu_me/entities/controlGroup.dart';
import 'package:qu_me/util.dart';

abstract class FaderInfo {
  final int id; // global id
  final int displayId; // not user defined id for send
  final String technicalName; // not user defined name for send
  final String name; // user defined name
  final Color color;
  final String personName; // name of the musician
  final bool explicitMuteOn; // Explicitly muted
  final UnmodifiableSetView<ControlGroup> controlGroups; // DCA or Mute Groups

  FaderInfo(
    this.id,
    this.displayId,
    this.technicalName,
    this.name,
    this.color,
    this.personName,
    this.explicitMuteOn,
    Set<ControlGroup> controlGroups,
  ) : this.controlGroups = unmodifiableSet<ControlGroup>(controlGroups);

  bool get stereo;

  // Either explicitly muted or muted through a group
  bool get muted => explicitMuteOn || controlGroups.any((cg) => cg.muteOn);

  FaderInfo copyWith({
    String name,
    String personName,
    bool explicitMuteOn,
    Set<ControlGroup> controlGroups,
  });
}
