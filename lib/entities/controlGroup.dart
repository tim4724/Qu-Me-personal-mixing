class ControlGroup {
  final int id;
  final ControlGroupType type;
  final bool muteOn;

  ControlGroup(this.id, this.type, this.muteOn);
}

enum ControlGroupType {
  dca,
  muteGroup,
}
