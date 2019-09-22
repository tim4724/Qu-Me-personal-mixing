class Group {
  final int id;
  final String technicalName; // the not user defined name for group
  final String displayId; // short id of the group
  String name; // user defined name

  Group(this.id, this.technicalName, this.displayId) {
    name = technicalName;
  }
}
