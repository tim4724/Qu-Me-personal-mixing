import 'dart:ui';

class Group {
  final int id;
  final String technicalName; // the not user defined name for group
  final String displayId; // short id of the group
  String name; // user defined name
  Color color;

  Group(this.id, this.technicalName, this.displayId) {
    name = technicalName;
    color = Color(0xFF000000);
  }
}
