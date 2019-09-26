import 'dart:ui';

class Group {
  final int id;
  final String technicalName; // the not user defined name for group
  final String displayId; // short id of the group
  final bool nameUserDefined; // If the user is allowe to edit the name
  String name; // user defined name
  Color color;

  Group(this.id, this.technicalName, this.displayId, this.nameUserDefined) {
    name = technicalName;
    color = Color(0xFF000000);
  }
}
