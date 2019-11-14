class SendGroup {
  final int id;
  final SendGroupType sendGroupType;
  String name;

  SendGroup(this.id, this.sendGroupType);

  // If the user is allowed to edit the name
  bool get isNameUserDefined => sendGroupType != SendGroupType.All;

  // If the user is allowed to change the Assignment
  bool get isAssignementUserDefined => sendGroupType == SendGroupType.Custom;
}

enum SendGroupType {
  Custom,
  Me,
  All,
}
