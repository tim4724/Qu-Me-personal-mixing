import 'dart:convert';
import 'dart:typed_data';

import 'package:qu_me/entities/mix.dart';
import 'package:qu_me/entities/scene.dart';
import 'package:qu_me/entities/send.dart';

Uint8List lastSceneData;

Scene parse(Uint8List data) {
  lastSceneData = data;
  final sceneId = data[3];
  final sceneName = _readString(data, 12);
  print("Parsing scene \"$sceneName\" ($sceneId)");

  final blockLen = 192;

  final sends = List<Send>(39);
  final mixes = List<Mix>(7);

  // Mono input channels
  // Stereo input channels
  // Groups
  for (var i = 0, offset = 48; i < sends.length; i++, offset += blockLen) {
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
    var name = _readString(data, offset + 156);

    SendType type;
    int displayId;
    if (i >= 0 && i < 32) {
      type = SendType.monoChannel;
      displayId = i + 1;
    } else if (i >= 32 && i < 35) {
      type = SendType.stereoChannel;
      displayId = i - 31;
    } else {
      type = SendType.fxReturn;
      displayId = i - 34;
      if (name == null || name.isEmpty) {
        // if fx Return is not named, use the name of fx send
        name = _readString(data, offset + 156 + (blockLen * 20));
      }
    }

    print("$i ${data.sublist(offset, offset + blockLen)}");
    sends[i] = Send(i, type, displayId, name, linked);
  }

  // Mono Mix 1 - 4
  // Stereo Mix 5/6, 7/8, 9/10
  for (var i = 0, offset = 48 + 39 * blockLen;
      i < mixes.length;
      i++, offset += blockLen) {
    final name = _readString(data, offset + 156);

    MixType type;
    int displayId;
    if (i < 4) {
      type = MixType.mono;
      displayId = i + 1;
    } else {
      type = MixType.stereo;
      displayId = 5 + ((i - 4) * 2);
    }
    final sendValues = List<int>(39);

    // channel 1 send mix 1 = _readUint16(data, 11872) / 256 - 128
    var sendValueOffset = 11872 + i * 100;
    // TODO channel 2, 3,...
    for (var j = 0; j < sendValues.length; j++, sendValueOffset += 2) {
      sendValues[j] = _readUint16(data, sendValueOffset);
    }
    // TODO PAN

    mixes[i] = Mix(39 + i, type, displayId, name, sendValues);
  }


  // Fx Send
  /*
  for (var i = 0, offset = 48 + 55 * blockLen; i < 4; i++, offset += blockLen) {
    final name = _readString(data, offset + 156);
  }
  */

  return Scene(sends, mixes);
}

String _readString(Uint8List data, int startIndex,
    {bool allowInvalid = false}) {
  final stringBytes = data.sublist(startIndex, data.indexOf(0x00, startIndex));
  return ascii.decode(stringBytes, allowInvalid: allowInvalid);
}

int _readUint16(Uint8List data, int startIndex) {
  return data[startIndex] | data[startIndex + 1] << 8;
}

compare(Uint8List oldData, Uint8List newData) {
  var dif = [];
  for (int i = 0; i < oldData.length; i++) {
    if (oldData[i] != newData[i]) {
      dif.add(i);
    }
  }
  print(dif);
  return dif;
}
