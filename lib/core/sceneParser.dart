import 'dart:convert';
import 'dart:typed_data';

import 'package:qu_me/entities/controlGroup.dart';
import 'package:qu_me/entities/mix.dart';
import 'package:qu_me/entities/scene.dart';
import 'package:qu_me/entities/send.dart';

Uint8List _lastSceneData = Uint8List(0);
const _blockLen = 192;

Scene parse(Uint8List data, int mixId) {
  _debugCompare(data);

  final sceneId = data[3];
  final sceneName = _readString(data, 12);
  print("Parsing scene \"$sceneName\" ($sceneId)");

  final scene = Scene();

  final allDcaGroups = List<ControlGroup>(4);
  final allMuteGroups = List<ControlGroup>(4);
  for (int i = 0; i < allDcaGroups.length; i++) {
    final muteOn = (data[24314 + i * 14]) == 1;
    allDcaGroups[i] = ControlGroup(i, ControlGroupType.dca, muteOn);
  }
  for (int i = 0; i < allMuteGroups.length; i++) {
    final muteOn = data[21480] >> i & 0x01 == 1;
    allMuteGroups[i] = ControlGroup(i, ControlGroupType.muteGroup, muteOn);
  }
  scene.controlGroups.setRange(0, 8, [...allDcaGroups, ...allMuteGroups]);

  // Mono input channels 1 - 32, Stereo input channels 1 - 3, Fx Return 1 - 4
  // TODO: Group?
  for (int i = 0, offset = 48;
      i < scene.sends.length;
      i++, offset += _blockLen) {
    final muteOn = data[offset + 136] == 1;
    final linked = data[offset + 144] == 1;
    final panLinked = linked && data[offset + 149] >> 3 & 1 == 1;
    final muteGroupData = data[offset + 140];
    var name = _readString(data, offset + 156);
    final dcaData = data[offset + 166];

    SendType type;
    int displayId;
    if (i < 32) {
      type = SendType.monoChannel;
      displayId = i + 1;
      scene.sendsLevelLinked[i] = linked;
      scene.sendsPanLinked[i] = panLinked;
    } else if (i >= 32 && i < 35) {
      type = SendType.stereoChannel;
      displayId = i - 31;
    } else {
      type = SendType.fxReturn;
      displayId = i - 34;
      if (name == null || name.isEmpty) {
        // if fx Return is not named, use the name of fx send
        // TODO: only for fx 1 + 2 ????
        name = _readString(data, offset + 156 + (_blockLen * 20));
      }
    }

    final controlGroups = _getControlGroupAssignement(
        dcaData, muteGroupData, allDcaGroups, allMuteGroups);
    scene.sends[i] =
        Send(i, type, displayId, name, null, muteOn, controlGroups);
  }

  // Mono Mix 1 - 4, Stereo Mix 5/6, 7/8, 9/10
  // TODO Mix-Group?
  for (int i = 0, offset = 48 + 39 * _blockLen;
      i < scene.mixes.length;
      i++, offset += _blockLen) {
    final muteOn = data[offset + 136] == 1;
    final muteGroupData = data[offset + 140];
    final name = _readString(data, offset + 156);
    final dcaData = data[offset + 166];

    final type = i < 4 ? MixType.mono : MixType.stereo;
    final displayId = i < 4 ? i + 1 : 2 * i - 3;

    final controlGroups = _getControlGroupAssignement(
        dcaData, muteGroupData, allDcaGroups, allMuteGroups);

    scene.mixes[i] =
        Mix(39 + i, type, displayId, name, null, muteOn, controlGroups);

    final masterLevelOffset = 7662 + i * 192;
    scene.mixesLevelInDb[i] = _readUint16(data, masterLevelOffset) / 256 - 128;
  }

  // Level and pan for sends of specific mix
  if (mixId != null && mixId >= scene.mixes[0].id) {
    final mixIndex = mixId - scene.mixes[0].id;
    var levelOffset = 11872 + mixIndex * 8;
    for (int j = 0; j < scene.sendLevelsInDb.length; j++, levelOffset += 160) {
      scene.sendLevelsInDb[j] = _readUint16(data, levelOffset) / 256.0 - 128.0;
    }
    var assignOffset = 11877 + mixIndex * 8;
    for (int j = 0; j < scene.sendAssigns.length; j++, assignOffset += 160) {
      scene.sendAssigns[j] = data[assignOffset] == 1;
    }

    if (scene.mixes[mixIndex].mixType == MixType.stereo) {
      var panOffset = 11906 + (mixIndex - 4) * 8;
      for (var j = 0; j < scene.sendPans.length; j++, panOffset += 160) {
        scene.sendPans[j] = _readUint16(data, panOffset);
      }
    }
  }

  // Fx Send
  /*
  for (var i = 0, offset = 48 + 55 * blockLen; i < 4; i++, offset += blockLen) {
    final name = _readString(data, offset + 156);
  }
  */
  return scene;
}

Set<T> _getControlGroupAssignement<T>(
    int val, val2, List<T> all, List<T> all2) {
  final result = Set<T>();
  for (int i = 0; i < all.length; i++) {
    if ((val >> i) & 0x01 == 0x01) {
      result.add(all[i]);
    }
  }
  for (int i = 0; i < all2.length; i++) {
    if ((val2 >> i) & 0x01 == 0x01) {
      result.add(all2[i]);
    }
  }
  return result;
}

String _readString(Uint8List data, int startIndex,
    {bool allowInvalid = false}) {
  final stringBytes = data.sublist(startIndex, data.indexOf(0x00, startIndex));
  return ascii.decode(stringBytes, allowInvalid: allowInvalid);
}

int _readUint16(Uint8List data, int startIndex) {
  return data[startIndex] | data[startIndex + 1] << 8;
}

_debugCompare(Uint8List newData) {
  List<int> dif = [];
  for (int i = 0; i < _lastSceneData.length; i++) {
    if (_lastSceneData[i] != newData[i]) {
      dif.add(i);
    }
  }
  _lastSceneData = newData;

  print("\nScene dif");
  for (var index in dif) {
    final oldValue = _lastSceneData[index];
    final newValue = newData[index];
    print("index: $index \t oldValue: $oldValue \t newValue: $newValue");
  }
  print("");
}

/*
hpf, gate, eq, compressor: byte 0 - 120
fader???: 121 - 123
main send (or master if mix?): 126 - 128
gain??: 129
gain??: 152
name: 156
source: 132, 139
linked: 144
phantom: 154
pad: 155
id: 183
mute: 184
 */
