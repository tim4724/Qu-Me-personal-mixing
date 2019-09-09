import 'dart:io';

import 'package:qu_me/entities/scene.dart';

class Mixer {
  final String name;
  final InternetAddress address;
  DateTime lastHeartbeat;
  String firmwarVersion;
  int mixerType; // TODO check if initialized with null
  Scene scene;

  Mixer(this.name, this.address, [this.lastHeartbeat]) {
    if (lastHeartbeat == null) {
      lastHeartbeat = DateTime.now();
    }
  }

  bool isReady() {
    return lastHeartbeat != null && mixerType != null && scene != null;
  }
}

class MixerType {
  static const QU_16 = 0x01;
  static const QU_24 = 0x02;
  static const QU_32 = 0x03;
  // TODO: other qu mixers
}
