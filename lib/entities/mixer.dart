import 'dart:io';

class Mixer {
  final String name;
  final InternetAddress address;
  int mixerType;
  String firmwareVersion;

  Mixer(this.name, this.address);

  @override
  String toString() {
    return 'Mixer{name: $name, address: $address, mixerType: $mixerType, firmwareVersion: $firmwareVersion}';
  }
}

class MixerType {
  static const QU_16 = 0x01;
  static const QU_24 = 0x02;
  static const QU_32 = 0x03;
// TODO: other qu mixers
}
