class MuteableGroup {
  final int id;
  final MutableGroupType type;
  final bool muteOn;

  MuteableGroup(this.id, this.type, this.muteOn);
}

enum MutableGroupType {
  dca,
  muteGroup,
}
