class Send {
  final SendType sendType;
  final int id;
  String name;
  bool faderLinked;

  Send(this.sendType, this.id, this.name, this.faderLinked);

  @override
  String toString() {
    return 'Send{sendType: $sendType, id: $id, name: $name, faderLinked: $faderLinked}';
  }

}

enum SendType { monoChannel, stereoChannel, fxReturn, group }
