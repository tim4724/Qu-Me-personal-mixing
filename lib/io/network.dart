import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:hex/hex.dart';
import 'package:qu_me/core/model/connectionModel.dart';
import 'package:qu_me/core/model/faderLevelPanModel.dart';
import 'package:qu_me/core/model/mainSendMixModel.dart';
import 'package:qu_me/core/model/sendGroupModel.dart';
import 'package:qu_me/core/sceneParser.dart' as sceneParser;
import 'package:qu_me/entities/controlGroup.dart';
import 'package:qu_me/entities/mixer.dart';
import 'package:qu_me/entities/scene.dart';
import 'package:qu_me/entities/send.dart';
import 'package:qu_me/io/networkMetersListener.dart' as metersListener;

Socket _socket;
int _currentMixIndex = -1;

void connect(String name, InternetAddress address) async {
  if (address.isLoopback) {
    _socket?.destroy();
    _socket = null;
    connectionModel.onStartLoadingScene();
    Future.delayed(Duration(milliseconds: 500), () {
      connectionModel.onMixerVersion(MixerType.QU_16, "0");
      final mixId = mainSendMixModel.currentMixIdNotifier.value;
      _onSceneParsed(buildDemoScene(mixId));
    });
  } else {
    _connect(address);
  }
}

void changeFaderLevel(int id, double levelInDb) {
  if (_socket == null || _currentMixIndex == -1) {
    return;
  }
  final value = ((levelInDb + 128.0) * 256.0).toInt();
  final valueId = id < 39 ? 0x0a : 0x07;
  final param2 = id < 39 ? _currentMixIndex : 0x07;
  final packet = [
    0x7F, // System Packet
    0x03, // Group Id
    0x08, // Len
    0x00, // Len
    0x04, //
    0x04, //
    valueId,
    0x00,
    id,
    param2
  ];
  packet.addAll(_fromUint16(value));
  _socket.add(packet);
}

void changeFaderPan(int id, int value) {
  if (_socket == null || _currentMixIndex == -1) {
    return;
  }
  // TODO: Do something useful
}

void changeMute(int id, bool muteOn) {
  if (_socket == null) {
    return;
  }
  // Not tested with non mixes
  final packet = [
    0x7F, // System Packet
    0x03, // Group Id
    0x08, // Len
    0x00, // Len
    0x04, //
    0x04, //
    0x06,
    0x00,
    id,
    0x07,
    muteOn ? 0x01 : 0x00,
    0x00
  ];
  _socket.add(packet);
}

void changeSelectedMix(int mixId, int mixIndex) {
  _currentMixIndex = mixIndex;
  if (_socket == null) {
    // For demo scene
    // TODO: implement demo mode better?
    connectionModel.onStartLoadingScene();
    Future.delayed(Duration(milliseconds: 1000), () {
      final mixId = mainSendMixModel.currentMixIdNotifier.value;
      _onSceneParsed(buildDemoScene(mixId));
    });
    return;
  }

  // Listen for future Mix Master Fader Level changes?
  final magicData = Uint8List(36);
  magicData[0] = 0x13;
  final magicValue = _fromUint16(0x80 * pow(2, mixIndex));
  magicData[8] = magicValue[0];
  magicData[9] = magicValue[1];
  _socket.add(_buildSystemPacket(0x04, [0x03, mixId]));
  _socket.add(_buildSystemPacket(0x04, magicData));

  // _socket.add(_buildSystemPacket(
  //      0x04,
  //      HEX.decode(130000000000000000010000000000000000000000000000000000000000000000000000
  //          "130000000000000080000000000000000000000000000000000000000000000000000000")));

  // Listen for future send level changes for new mix?
  final magicData1 = Uint8List(36);
  magicData1[0] = 0x14;
  magicData1[4] = 0x01 * pow(2, mixIndex);
  _socket.add(_buildSystemPacket(0x04, [0x04, mixId]));
  _socket.add(_buildSystemPacket(0x04, magicData1));
  // _socket.add(_buildSystemPacket(
  //    0x04,
  //    HEX.decode(
  //        "140000000100000000000000000000000000000000000000000000000000000000000000")));

  _requestSceneState();
}

void close() {
  _socket?.destroy();
  _socket = null;
}

void _connect(InternetAddress address) async {
  _socket = await Socket.connect(address, 51326);
  _socket.setOption(SocketOption.tcpNoDelay, true);

  final byteStreamController = StreamController<int>();
  _socket.listen(
    (dataEvent) {
      for (final byte in dataEvent) {
        // TODO better way?
        byteStreamController.add(byte);
      }
    },
    onDone: () {
      // TODO: do something useful
      print("Socket was closed");
      _socket?.destroy();
      metersListener.stop();
      byteStreamController.close();
      connectionModel.reset();
      mainSendMixModel.reset();
    },
    onError: _onError,
    cancelOnError: false,
  );
  // TODO: init timeout?!

  final metersSocketPort = await metersListener.getPort();
  // Request meters
  // Group Id 0x00 -> "QU-You"?
  _socket.add(_buildSystemPacket(0x00, _fromUint16(metersSocketPort)));
  // request mixer version
  _socket.add(_buildSystemPacket(0x04, [0x00, 0x00]));
  // Check default password (aka is no password set)
  _socket.add(_buildSystemPacket(0x04, HEX.decode("01040000090e6490")));
  // Check password "inear"
  _socket.add(_buildSystemPacket(0x04, HEX.decode("0104000046c340f4")));
  // TODO: Or rquest after mixer version received
  _requestSceneState();

  final queue = StreamQueue<int>(byteStreamController.stream);
  while (await queue.hasNext) {
    final type = await queue.next;
    switch (type) {
      case 0x7F:
        // System packet
        final groupId = await queue.next;
        final dataLen = _getUint16(await queue.take(2));
        final data = await queue.take(dataLen);
        _onSystemPacketReceived(groupId, data);
        break;
      case 0xF7:
        // DSP packet (always 9 bytes -> 8 data bytes)
        final data = await queue.take(8);
        _onDspPacketReceived(DspPacket(Uint8List.fromList(data)));
        break;
      default:
        print("unexpected type: $type");
        break;
    }
  }
}

void _onSystemPacketReceived(int groupId, List<int> data) {
  switch (groupId) {
    case 0x00:
      final dstPort = _getUint16(data);
      print("Listen for meters and send regular heartbeat to port $dstPort");
      metersListener.start(_socket.remoteAddress, dstPort);
      break;
    case 0x01:
      final mixerType = data[0];
      final firmwareVersion = "${data[1]}.${data[2]}-${_getUint16(data, 4)}";
      print("Received MixerType: $mixerType Firmware: $firmwareVersion");
      connectionModel.onMixerVersion(mixerType, firmwareVersion);
      break;
    case 0x02:
      if (data[0] == 4 && data[1] == 0) {
        print("Password incorrect");
      } else if (data[0] == 4 && data[1] == 1) {
        print("Password correct");
      }
      break;
    case 0x06:
      print("Received scene");
      final mixId = mainSendMixModel.currentMixIdNotifier.value;
      final scene = sceneParser.parse(Uint8List.fromList(data), mixId);
      _onSceneParsed(scene);
      break;
    case 0x07:
      print("Unknown Packet: group id: $groupId; dataLen: ${data.length}");
      print("data: $data");
      break;
    case 0x08:
      final faderId = data[1];
      final name = ascii.decode(data.sublist(2, data.indexOf(0x00, 2)));
      print("Rename faderinfo: $faderId new name: $name");
      mainSendMixModel.updateFaderInfo(faderId, name: name);
      break;
    case 0x09:
      final faderId = data[1];
      final linkOn = data[2] == 1;
      final linkPan = linkOn && (data[7] >> 3) & 0x01 == 1;
      print("Update Channel $faderId Link: $linkOn PanLink: $linkPan");
      faderLevelPanModel.onLink(faderId, linkOn, linkPan);
      // TODO: Test this case
      break;
    default:
      print("unknown packet group id: $groupId; dataLen: ${data.length}");
      print("data: $data");
      break;
  }
}

void _onDspPacketReceived(DspPacket dspPacket) {
  if (dspPacket.targetGroup != 4) {
    print("Invalid target Group. DspPacket: $dspPacket");
    return;
  }

  final faderId = dspPacket.param1;
  switch (dspPacket.valueId) {
    case 0x0a:
      print("Unknown ValueId: 0x0a DspPacket: $dspPacket");
      break;
    // ???
    case 0x07:
      final valueInDb = (dspPacket.value / 256.0 - 128.0);
      print("Fader value: ${dspPacket.value}");
      faderLevelPanModel.onLevel(faderId, valueInDb);
      //TODO on "link" level needs to change maybe
      break;
    case 0x06:
      final muteOn = dspPacket.value == 1;
      print("Mute fader $faderId: $muteOn");
      mainSendMixModel.updateFaderInfo(faderId, explicitMuteOn: muteOn);
      break;
    case 0x09:
      final assignOn = dspPacket.value == 1;
      print("Assign send $faderId to current Mix: $assignOn");
      sendGroupModel.updateAvailabilitySend(faderId, assignOn);
      break;
    case 0x0C:
      // Pan changed 0 => left, 74 => right, 38 => center
      print("Pan Fader ${dspPacket.param1 + 1} ${dspPacket.value}");
      //TODO on "link pan" pan needs to change maybe
      faderLevelPanModel.onPan(faderId, dspPacket.value);
      break;
    case 0x0F:
      print("Update mute state of mutegroups");
      for (int muteGroupId = 0; muteGroupId < 4; muteGroupId++) {
        final muteOn = (dspPacket.value >> muteGroupId) & 0x01 == 0x01;
        final type = ControlGroupType.muteGroup;
        mainSendMixModel.updateControlGroup(muteGroupId, type, muteOn);
      }
      break;
    case 0x0D:
      final muteGroupId = dspPacket.param2;
      final assignOn = dspPacket.value == 1;
      print("Mutegroup $muteGroupId Fader $faderId Assignment $assignOn");
      mainSendMixModel.updateControlGroupAssignment(
          muteGroupId, ControlGroupType.muteGroup, faderId, assignOn);
      break;
    case 0x16:
      final dcaGroupId = faderId - 205;
      final type = ControlGroupType.dca;
      final muteOn = dspPacket.value != 0;
      print("Upate DCA Group: $dcaGroupId MuteOn: $muteOn");
      mainSendMixModel.updateControlGroup(dcaGroupId, type, muteOn);
      break;
    case 0x17:
      final dcaGroupId = dspPacket.param2;
      final type = ControlGroupType.dca;
      final assignOn = dspPacket.value == 1;
      print("DCA Group $dcaGroupId Fader $faderId Assignment $assignOn");
      mainSendMixModel.updateControlGroupAssignment(
          dcaGroupId, type, faderId, assignOn);
      break;
    default:
      print("Unknown ValueId ${dspPacket.valueId} DspPacket: $dspPacket");
      break;
  }
}

class DspPacket {
  final Uint8List data;

  DspPacket(this.data);

  // knob, touch, ipad...
  int get controlId => data[0];

  // mix, peq, ...
  int get targetGroup => data[1];

  // fader, ...
  int get valueId => data[2];

  // ipad, mixer, ...
  int get clientId => data[3];

  int get param1 => data[4];

  int get param2 => data[5];

  int get value => _getUint16(data, 6);

  @override
  String toString() {
    return 'DspPacket{controlId: $controlId, targetGroup: $targetGroup, '
        'valueId: $valueId, clientId: $clientId, param1: $param1, param2: $param2, value $value}';
  }
}

void _requestSceneState() {
  connectionModel.onStartLoadingScene();
  _socket.add(_buildSystemPacket(0x04, [0x02, 0x00]));
}

void _onSceneParsed(Scene scene) {
  mainSendMixModel.initControlGroups(scene.controlGroups);
  mainSendMixModel.initMixes(scene.mixes);
  mainSendMixModel.initSends(scene.sends);

  int maxMonoChannels = 32;
  // TODO: What if ConnectionModel is not initialized
  if (connectionModel.type == MixerType.QU_16) {
    maxMonoChannels = 16;
  }
  // TODO add selection for QU-24, Qu-32 ...
  // Maybe move logic to sceneparser
  sendGroupModel.initAvailableSends(scene.sends
      .where((send) =>
          scene.sendAssigns[send.id] &&
          (send.sendType != SendType.monoChannel || send.id < maxMonoChannels))
      .map((send) => send.id)
      .toList());

  faderLevelPanModel.initLinks(scene.sendsLevelLinked, scene.sendsPanLinked);
  faderLevelPanModel.initLevels(scene.sendLevelsInDb);
  faderLevelPanModel.initLevels(scene.mixesLevelInDb, scene.mixes[0].id);
  faderLevelPanModel.initPans(scene.sendPans);

  connectionModel.onFinishedLoadingScene();
}

void print(String data) {
  print("NETWORK: " + data);
}

void _onError(e) {
  print(e);
}

Uint8List _buildSystemPacket(int groupId, List<int> value) {
  return Uint8List.fromList(
      [0x7f, groupId, value.length, value.length >> 8]..addAll(value));
}

int _getUint16(List<int> data, [int index = 0]) {
  return data[index] | data[index + 1] << 8;
}

Uint8List _fromUint16(int value) {
  return Uint8List.fromList([value, value >> 8]);
}
