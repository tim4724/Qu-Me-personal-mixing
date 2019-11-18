import 'dart:convert';
import 'dart:typed_data';

import 'package:qu_me/entities/controlGroup.dart';
import 'package:qu_me/entities/mix.dart';
import 'package:qu_me/entities/scene.dart';
import 'package:qu_me/entities/send.dart';

Uint8List _lastSceneData = Uint8List(0);
const _blockLen = 192;

Scene parse(Uint8List data) {
  final dif = compare(_lastSceneData, data);
  print("Scene dif");
  for (var index in dif) {
    print("index: $index \t oldValue: ${_lastSceneData[index]} "
        "\t newValue: ${data[index]}");
  }
  print("");

  _lastSceneData = data;
  final sceneId = data[3];
  final sceneName = _readString(data, 12);
  print("Parsing scene \"$sceneName\" ($sceneId)");

  final allDcaGroups = List<ControlGroup>(4);
  final allMuteGroups = List<ControlGroup>(4);
  final sends = List<Send>(39);
  final sendsLevelLinked = List<bool>(39);
  final sendsPanLinked = List<bool>(39);

  // DCA1 Mute: data[24314] == 1
  // DCA2 Mute: data[24328] == 1
  // DCA3 Mute: data[24342] == 1
  // DCA4 Mute: data[24356] == 1
  for (int i = 0; i < allDcaGroups.length; i++) {
    final muteOn = (data[24314 + i * 14]) == 1;
    allDcaGroups[i] = ControlGroup(i, ControlGroupType.dca, muteOn);
  }
  // Channel one not in any dca: data[214] == 0;
  // Channel one in dca 1: data[214] == 1;
  // Channel one in dca 2: data[214] == 2;
  // Channel one in dca 1+2: data[214] == 3;

  // Mute group 1 mute: data[21480] == 1
  // Mute group 1 + 2 mute: data[21480] == 3
  final muteGroupMuteData = data[21480];
  for (int i = 0; i < allMuteGroups.length; i++) {
    final muteOn = muteGroupMuteData >> i & 0x01 == 1;
    allMuteGroups[i] = ControlGroup(i, ControlGroupType.muteGroup, muteOn);
  }
  // Channel 1 no mute groups: data[188] == 0
  // Channel 1 mute-group 1: data[188] == 1
  // Channel 1 mute-group 1 + 2: data[188] == 3

  // Mono input channels 1 - 32
  // Stereo input channels 1 - 3
  // Fx Return 1 - 4
  // TODO: Group?
  for (var i = 0, offset = 48; i < sends.length; i++, offset += _blockLen) {
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
    // mute: 184
    final muteOn = data[offset + 136] == 1;
    final muteGroupData = data[offset + 140];
    final linked = data[offset + 144] == 1;
    final panLinked = linked && data[offset + 149] >> 3 & 1 == 1;
    var name = _readString(data, offset + 156);
    final dcaData = data[offset + 166];

    SendType type;
    int displayId;
    if (i < 32) {
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
        // TODO: only for fx 1 + 2 ????
        name = _readString(data, offset + 156 + (_blockLen * 20));
      }
    }

    final controlGroups = getControlGroupAssignement(
        dcaData, muteGroupData, allDcaGroups, allMuteGroups);

    sendsLevelLinked[i] = linked;
    sendsPanLinked[i] = panLinked;
    sends[i] = Send(i, type, displayId, name, muteOn, controlGroups);
  }

  final mixes = List<Mix>(7);
  final mixMasterLevels = List<double>(7);

  // Mono Mix 1 - 4
  // Stereo Mix 5/6, 7/8, 9/10
  // TODO Mix-Group?
  // offset 48 + 39 * 192 = 7536
  for (var i = 0, offset = 48 + 39 * _blockLen;
      i < mixes.length;
      i++, offset += _blockLen) {
    final muteOn = data[offset + 136] == 1;
    final muteGroupData = data[offset + 140];
    final name = _readString(data, offset + 156);
    final dcaData = data[offset + 166];

    final type = i < 4 ? MixType.mono : MixType.stereo;
    final displayId = i < 4 ? i + 1 : 2 * i - 3;

    final controlGroups = getControlGroupAssignement(
        dcaData, muteGroupData, allDcaGroups, allMuteGroups);

    // channel 1 send mix 1 = _readUint16(data, 11872) / 256.0 - 128.0;
    // channel 2 send mix 1 = _readUint16(data, 12032) / 256.0 - 128.0;
    // channel 1 send mix 2 = _readUint16(data, 11880) / 256.0 - 128.0;
    // Mix 1 Master Fader = _readUint16(data, 7662) / 256.0 - 128.0;
    // Mix 2 Master Fader = _readUint16(data, 7854) / 256.0 - 128.0;
    // channel 1 assign send mix 1 = data[11877] == 1;
    // channel 1 assign send mix 2 = data[11885] == 1;
    // channel 2 assign send mix 2 = data[12045] == 1;
    final sendLevelsInDb = List<double>(39);
    var sendLevelOffset = 11872 + i * 8;
    for (var j = 0; j < sendLevelsInDb.length; j++, sendLevelOffset += 160) {
      sendLevelsInDb[j] = _readUint16(data, sendLevelOffset) / 256.0 - 128.0;
    }

    // Mix 5/6 pan channel 1: 11906
    // Mix 5/6 pan channel 2: 12066
    // Mix 7/8 pan channel 1: 11914
    final sendPans = List<int>(39);
    if (type == MixType.stereo) {
      var sendPanOffset = 11906 + (i - 4) * 8;
      for (var j = 0; j < sendPans.length; j++, sendPanOffset += 160) {
        sendPans[j] = _readUint16(data, sendPanOffset);
      }
    }

    var sendAssignOffset = 11877 + i * 8;
    final sendAssigns = List<bool>(39);
    for (var j = 0; j < sendAssigns.length; j++, sendAssignOffset += 160) {
      sendAssigns[j] = data[sendAssignOffset] == 1;
    }

    mixes[i] = Mix(39 + i, type, displayId, name, muteOn, controlGroups,
        sendLevelsInDb, sendPans, sendAssigns);

    final masterLevelOffset = 7662 + i * 192;
    mixMasterLevels[i] = _readUint16(data, masterLevelOffset) / 256 - 128;
  }

  // Fx Send
  /*
  for (var i = 0, offset = 48 + 55 * blockLen; i < 4; i++, offset += blockLen) {
    final name = _readString(data, offset + 156);
  }
  */
  final controlGroups = [...allDcaGroups, ...allMuteGroups];
  return Scene(sends, mixes, sendsLevelLinked, sendsPanLinked, mixMasterLevels,
      controlGroups);
}

Set<T> getControlGroupAssignement<T>(int val, val2, List<T> all, List<T> all2) {
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
