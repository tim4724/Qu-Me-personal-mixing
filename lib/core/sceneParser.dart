import 'dart:convert';
import 'dart:typed_data';

import 'package:qu_me/entities/mix.dart';
import 'package:qu_me/entities/scene.dart';
import 'package:qu_me/entities/send.dart';

Scene parse(Uint8List data) {
  final sceneId = data[3];
  final sceneName = readString(data, 12);
  print("Parsing scene \"$sceneName\" ($sceneId)");

  final blockLen = 192;

  final sends = List<Send>();
  final mixes = List<Mix>();

  // Mono input channels
  // Stereo input channels
  // Groups
  for (var i = 0, offset = 48; i < 39; i++, offset += blockLen) {
    // hpf, gate, eq, compressor: byte 0 - 120
    // fader???: 121 - 123
    // main send (or master if mix?): 126 - 128
    // gain??: 129
    // gain??: 152
    // name: 156
    // source: 132, 139
    // linked: 144
    // phantom: 154
    // pad: 155
    // id: 183

    final linked = data[offset + 144] == 1; // todo check link-fader
    final name = readString(data, offset + 156);
    var id = data[offset + 183];

    SendType type;
    if (i >= 0 && i < 32) {
      type = SendType.monoChannel;
    } else if (i >= 32 && i < 35) {
      type = SendType.stereoChannel;
    } else {
      // TODO: check if group or mix mode!!!
      type = SendType.group;
      id = i - 35;
    }

    sends.add(Send(type, id, name, linked));
  }

  // Mono Mix 1 - 4
  // Stereo Mix 5/6, 7/8, 9/10
  for (var i = 0, offset = 48 + 39 * blockLen; i < 7; i++, offset += blockLen) {
    final name = readString(data, offset + 156);
    mixes.add(Mix(i < 4 ? MixType.mono : MixType.stereo, i, name));
  }

  // Fx Return ?
  for (var i = 0, offset = 48 + 55 * blockLen; i < 4; i++, offset += blockLen) {
    final name = readString(data, offset + 156);
    sends.add(Send(SendType.fxReturn, i, name, false));
  }

  return Scene(sends, mixes);
}

String readString(Uint8List data, int startIndex, {bool allowInvalid = false}) {
  final stringBytes = data.sublist(startIndex, data.indexOf(0x00, startIndex));
  return ascii.decode(stringBytes, allowInvalid: allowInvalid);
}

int readUint16(Uint8List data, int startIndex) {
  return data[startIndex] | data[startIndex + 1] << 8;
}
