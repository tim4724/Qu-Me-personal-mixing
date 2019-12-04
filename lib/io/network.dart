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
import 'package:qu_me/io/heartbeat.dart' as heartbeat;
import 'package:qu_me/io/networkMetersListener.dart' as metersListener;

Socket _socket;
int _currentMixIndex = -1; // TODO is this variable necessary?
final _connectionModel = ConnectionModel();
final _mainSendMixModel = MainSendMixModel();
final _sendGroupModel = SendGroupModel();
final _levelPanModel = FaderLevelPanModel();

void connect(String name, InternetAddress address) async {
  if (address.isLoopback) {
    _socket?.destroy();
    _socket = null;
    Future.delayed(Duration(milliseconds: 500), () {
      _connectionModel.onMixerVersion(MixerType.QU_16, "0");
      _onSceneReceived(buildDemoScene());
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
  print("Set level $id $value");
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
  // Mix 1 mute on:
  // 0x7F 0x03 0x08 0x00 0x04 0x04 0x06 0x00 0x27 0x07 0x01 0x00
  // Mix 1 mute off:
  // 0x7F 0x03 0x08 0x00 0x04 0x04 0x06 0x00 0x27 0x07 0x00 0x00
  // Mix 9/10 mute on:
  // 0x7F 0x03 0x08 0x00 0x04 0x04 0x06 0x00 0x2d 0x07 0x01 0x00
  // Mix 9/10 mute off:
  // 0x7F 0x03 0x08 0x00 0x04 0x04 0x06 0x00 0x2d 0x07 0x00 0x00
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
  _connectionModel.onLoadingScene();

  if (_socket == null) {
    // For demo scene
    // TODO: implement demo mode better?
    Future.delayed(Duration(milliseconds: 500), () {
      _onSceneReceived(buildDemoScene());
    });
    return;
  }
  _currentMixIndex = -1;

  // Listen for future Mix Master Fader changes?
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

  // Request current scene state
  // - to receive latest send levels, send pans, assignements for new mix
  // - to receive latest mix master fader level
  _requestSceneState();

  _currentMixIndex = mixIndex;
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
      heartbeat.stop();
      byteStreamController.close();
      _connectionModel.reset();
      _mainSendMixModel.reset();
    },
    onError: _onError,
    cancelOnError: false,
  );
  // TODO: init timeout?!

  final metersSocket =
      await RawDatagramSocket.bind(InternetAddress.ANY_IP_V4, 0);
  metersListener.listen(metersSocket);

  // Request meters
  // Group Id 0x00 -> "QU-You"?
  _socket.add(_buildSystemPacket(0x00, _fromUint16(metersSocket.port)));

  // request mixer version
  _socket.add(_buildSystemPacket(0x04, [0x00, 0x00]));

  // Check default password (aka is no password set)
  _socket.add(_buildSystemPacket(0x04, HEX.decode("01040000090e6490")));
  // Check password "inear"
  _socket.add(_buildSystemPacket(0x04, HEX.decode("0104000046c340f4")));

  // TODO: Or rquest after mixer version received
  _requestSceneState();

  StreamQueue<int> queue = StreamQueue(byteStreamController.stream);
  while (await queue.hasNext) {
    int type = await queue.next;
    switch (type) {
      case 0x7F:
        // System packet
        final groupId = await queue.next;
        final dataLen = _getUint16(await queue.take(2));
        final data = await queue.take(dataLen);
        switch (groupId) {
          case 0x00:
            final dstPort = _getUint16(data);
            heartbeat.start(metersSocket, address, dstPort);
            break;
          case 0x01:
            _connectionModel.onMixerVersion(
                data[0], "${data[1]}.${data[2]}-${_getUint16(data, 4)}");
            break;
          case 0x02:
            if (data[0] == 4 && data[1] == 0) {
              print("password incorrect");
            } else if (data[0] == 4 && data[1] == 1) {
              print("password correct");
            }
            break;
          case 0x06:
            final mixId = _mainSendMixModel.currentMixIdNotifier.value;
            final scene = sceneParser.parse(Uint8List.fromList(data), mixId);
            _onSceneReceived(scene);
            break;
          case 0x07:
            // Don't know what this is...
            print("group id: $groupId; dataLen: $dataLen");
            print("data: $data");
            break;
          case 0x08:
            // Rename Channel 1 to "Aaaaaa"
            // data: [0, 0, 65, 97, 97, 97, 97, 0, 0, 0, 0]
            // Rename Channel 2 to "Bbbbbb"
            // data: [0, 1, 66, 98, 98, 98, 98, 98, 0, 0, 0]
            // Rename ST1 to "Cccccc"
            // data: [0, 32, 67, 99, 99, 99, 99, 99, 0, 0, 0]
            // Rename FXRet4 to "Dddddd"
            //data: [0, 38, 68, 100, 100, 100, 100, 100, 0, 0, 0]
            // Rename FXSend 1 to "Asdf2"
            // data: [0, 55, 65, 115, 100, 102, 50, 0, 0, 0, 0]
            // rename mix 1 to "Asdf"
            // data: [0, 39, 65, 115, 100, 102, 0, 0, 0, 0, 0]
            // rename mix 9/10 to "Asdf"
            // data: [0, 45, 65, 115, 100, 102, 0, 0, 0, 0, 0]
            print("Rename data: $data");
            final faderId = data[1];
            final name = ascii.decode(data.sublist(2, data.indexOf(0x00, 2)));
            _mainSendMixModel.updateFaderInfo(faderId, name: name);
            break;
          case 0x09:
            // Channel 3 mix 7/8:
            // Link off completely
            // unknown packet group id: 9; dataLen: 10
            // data: [0, 3, 0, 0, 0, 0, 255, 255, 255, 255]
            // Link on completely:
            // I/flutter (12681): unknown packet group id: 9; dataLen: 10
            // I/flutter (12681): data: [0, 3, 1, 0, 0, 0, 255, 255, 255, 255]
            // link off pan:
            // 247 = 128 + 64 + 32 + 16 + 0 + 4 + 2 + 1
            // I/flutter (12681): unknown packet group id: 9; dataLen: 10
            // I/flutter (12681): data: [0, 3, 1, 0, 0, 0, 255, 247, 255, 255]
            final faderId = data[1];
            final linkOn = data[2] == 1;
            final linkPan = linkOn && (data[7] >> 3) & 0x01 == 1;
            _levelPanModel.onLink(faderId, linkOn, linkPan);
            // TODO: Test this case
            break;
          default:
            print("unknown packet group id: $groupId; dataLen: $dataLen");
            print("data: $data");
            break;
        }
        break;

      case 0xF7:
        // DSP packet (always 9 bytes -> 8 data bytes)
        final data = await queue.take(8);
        final dspPacket = DspPacket(Uint8List.fromList(data));
        print("$dspPacket");

        if (dspPacket.targetGroup == 4) {
          final faderId = dspPacket.param1;
          switch (dspPacket.valueId) {
            case 0x0a:
            // ???
            case 0x07:
              final valueInDb = (dspPacket.value / 256.0 - 128.0);
              _levelPanModel.onLevel(faderId, valueInDb);
              //TODO on "link" level needs to change maybe
              print("Fader value: ${dspPacket.value}");
              break;
            case 0x06:
              final muteOn = dspPacket.value == 1;
              _mainSendMixModel.updateFaderInfo(faderId,
                  explicitMuteOn: muteOn);
              print("Mute fader $faderId: $muteOn");
              break;
            case 0x09:
              final assignOn = dspPacket.value == 1;
              _sendGroupModel.updateAvailabilitySend(faderId, assignOn);
              print("Assign send $faderId to current Mix: $assignOn");
              break;
            case 0x0C:
              // Pan changed
              // Value == 0 => left
              // Value == 74 => right
              // Value == 38 => center
              print("Pan Fader ${dspPacket.param1 + 1} ${dspPacket.value}");
              //TODO on "link pan" pan needs to change maybe
              _levelPanModel.onPan(faderId, dspPacket.value);
              break;
            case 0x0F:
              // Mute Group 1 muteOn->true
              // DspPacket{controlId: 90, targetGroup: 4, valueId: 15, clientId: 0, param1: 255, param2: 0, value 1}

              // Mute Group 1 + 2 muteOn->true
              // DspPacket{controlId: 90, targetGroup: 4, valueId: 15, clientId: 0, param1: 255, param2: 0, value 3}

              // Mute Group 1 + 2 + 3 muteOn->true
              // DspPacket{controlId: 90, targetGroup: 4, valueId: 15, clientId: 0, param1: 255, param2: 0, value 7}

              for (int muteGroupId = 0; muteGroupId < 4; muteGroupId++) {
                final muteOn = (dspPacket.value >> muteGroupId) & 0x01 == 0x01;
                final type = ControlGroupType.muteGroup;
                _mainSendMixModel.updateControlGroup(muteGroupId, type, muteOn);
              }
              break;
            case 0x0D:
              final muteGroupId = dspPacket.param2;
              final assignOn = dspPacket.value == 1;
              _mainSendMixModel.updateControlGroupAssignment(
                  muteGroupId, ControlGroupType.muteGroup, faderId, assignOn);
              break;
            case 0x16:
              final dcaGroupId = faderId - 205;
              final type = ControlGroupType.dca;
              final muteOn = dspPacket.value != 0;
              _mainSendMixModel.updateControlGroup(dcaGroupId, type, muteOn);
              // DCA 1: muteOn -> true
              // DspPacket{controlId: 90, targetGroup: 4, valueId: 22, clientId: 0, param1: 205, param2: 0, value 1}
              // DCA 2: muteOn -> true
              // DspPacket{controlId: 90, targetGroup: 4, valueId: 22, clientId: 0, param1: 206, param2: 0, value 2}
              // DCA 3: muteOn -> true
              // DspPacket{controlId: 90, targetGroup: 4, valueId: 22, clientId: 0, param1: 207, param2: 0, value 4}
              // DCA 4: muteOn->true
              // DspPacket{controlId: 90, targetGroup: 4, valueId: 22, clientId: 0, param1: 208, param2: 0, value 8}
              // DCA 1: muteOn -> false
              // DspPacket{controlId: 90, targetGroup: 4, valueId: 22, clientId: 0, param1: 205, param2: 0, value 0}
              // DCA 2: muteOn -> false
              // DspPacket{controlId: 90, targetGroup: 4, valueId: 22, clientId: 0, param1: 206, param2: 0, value 0}
              // DCA 3: muteOn -> false
              // DspPacket{controlId: 90, targetGroup: 4, valueId: 22, clientId: 0, param1: 207, param2: 0, value 0}
              // DCA 4: muteOn -> false
              // DspPacket{controlId: 90, targetGroup: 4, valueId: 22, clientId: 0, param1: 208, param2: 0, value 0}
              // DCA 3: muteOn -> true
              // DspPacket{controlId: 90, targetGroup: 4, valueId: 22, clientId: 0, param1: 207, param2: 0, value 4}
              break;
            case 0x17:
              final dcaGroupId = dspPacket.param2;
              final assignOn = dspPacket.value == 1;
              _mainSendMixModel.updateControlGroupAssignment(
                  dcaGroupId, ControlGroupType.dca, faderId, assignOn);
              break;
            default:
              print("unexpected valueId: ${dspPacket.valueId}");
              break;
          }
        }
        break;
      default:
        print("unexpected type: $type");
        break;
    }
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
  // request scene state
  _socket.add(_buildSystemPacket(0x04, [0x02, 0x00]));
}

void _onSceneReceived(Scene scene) {
  _mainSendMixModel.initControlGroups(scene.controlGroups);
  _mainSendMixModel.initMixes(scene.mixes);
  _mainSendMixModel.initSends(scene.sends);

  int maxMonoChannels = 32;
  // TODO: What if ConnectionModel is not initialized
  if (_connectionModel.type == MixerType.QU_16) {
    maxMonoChannels = 16;
  }
  // TODO add selection for QU-24, Qu-32 ...

  List<int> availableSendIds = scene.sends
      .where((send) =>
          scene.sendAssigns[send.id] &&
          (send.sendType != SendType.monoChannel || send.id < maxMonoChannels))
      .map((send) => send.id)
      .toList();
  _sendGroupModel.initAvailableSends(availableSendIds);

  _levelPanModel.initLinks(scene.sendsLevelLinked, scene.sendsPanLinked);
  _levelPanModel.initLevels(scene.sendLevelsInDb);
  _levelPanModel.initPans(scene.sendPans);

  _connectionModel.onSceneLoaded();
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
