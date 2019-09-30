import 'package:flutter/widgets.dart';
import 'package:qu_me/entities/mutableGroup.dart';

abstract class FaderInfo {
  final int id; // global id
  final int displayId; // not user defined id for send
  final String technicalName; // not user defined name for send
  final String name; // user defined name
  final Color color;
  final String personName; // name of the musician
  final bool explicitMuteOn; // Explicitly muted
  final Set<MuteableGroup> mutableGroups; // TODO unmodiviable

  FaderInfo(
    this.id,
    this.displayId,
    this.technicalName,
    this.name,
    this.color,
    this.personName,
    this.explicitMuteOn,
    this.mutableGroups,
  );

  bool get stereo;

  // Either explicitly muted or muted through a group
  bool get muted => explicitMuteOn || mutableGroups.any((group) => group.muteOn);

  FaderInfo copyWith({
    String name,
    String personName,
    bool explicitMuteOn,
    Set<MuteableGroup> mutableGroups,
  });
}
