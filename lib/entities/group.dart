import 'dart:ui';

class Group {
  final int id;
  final String technicalName; // the not user defined name for group
  final String displayId; // short id of the group
  final bool nameUserDefined; // If the user is allowed to edit the name
  // If the user is allowed to change the Assignment
  final bool assignmentUserDefined;
  String name; // user defined name
  Color color;

  Group(this.id, this.technicalName, this.displayId, this.nameUserDefined,
      this.assignmentUserDefined) {
    name = technicalName;
    color = Color(0xFF000000);
  }
}
