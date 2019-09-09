class Mix {
  final MixType mixType;
  final int id;
  String name;

  Mix(this.mixType, this.id, this.name);

  @override
  String toString() {
    return 'Mix{mixType: $mixType, id: $id, name: $name}';
  }

}

enum MixType {
  mono, stereo
}