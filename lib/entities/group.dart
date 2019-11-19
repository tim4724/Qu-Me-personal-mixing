class SendGroup {
  final int id;
  final SendGroupType sendGroupType;
  final String name;

  const SendGroup(this.id, this.sendGroupType, [this.name]);

  // If the user is allowed to edit the name
  bool get isNameUserDefined => sendGroupType != SendGroupType.All;

  // If the user is allowed to change the Assignment
  bool get isAssignementUserDefined => sendGroupType == SendGroupType.Custom;

  SendGroup copyWithNewName(String name) {
    return SendGroup(this.id, this.sendGroupType, name);
  }
}

enum SendGroupType {
  Custom,
  Me,
  All,
}
