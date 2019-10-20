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
import 'package:qu_me/io/heartbeat.dart' as heartbeat;
import 'package:qu_me/io/networkMetersListener.dart' as metersListener;

Socket _socket;
int _currentMixIndex = -1;
final _levelPanModel = FaderLevelPanModel();

void connect(String name, InternetAddress address) async {
  if (address.isLoopback) {
    Future.delayed(Duration(milliseconds: 500), () {
      final mixerModel = ConnectionModel();
      mixerModel.onMixerVersion(MixerType.QU_16, "0");
      final mixingModel = MainSendMixModel();
      mixingModel.onScene(buildDemoScene());
    });
  } else {
    _connect(address);
  }
}

void _connect(InternetAddress address) async {
  final connectionModel = ConnectionModel();
  final mainSendMixModel = MainSendMixModel();
  final groupModel = SendGroupModel();

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
      connectionModel.reset();
      mainSendMixModel.reset();
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

  _requestSceneState();

  mixSelectChanged(39, 0);

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
            connectionModel.onMixerVersion(
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
            mainSendMixModel
                .onScene(sceneParser.parse(Uint8List.fromList(data)));
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
            mainSendMixModel.updateFaderInfo(faderId, name: name);
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

          // TODO: MuteGroup Assignement changed
          // TODO: DCA Assignement changed
          // TODO: Pan changed
          switch (dspPacket.valueId) {
            case 0x0a:
            // ???
            case 0x07:
              final valueInDb = (dspPacket.value / 256.0 - 128.0);
              _levelPanModel.onNewFaderLevel(faderId, valueInDb);
              print("Fader value: ${dspPacket.value}");
              break;
            case 0x06:
              final muteOn = dspPacket.value == 1;
              mainSendMixModel.updateFaderInfo(faderId, explicitMuteOn: muteOn);
              print("Mute fader $faderId: $muteOn");
              break;
            case 0x09:
              final assignOn = dspPacket.value == 1;
              groupModel.updateAvailabilitySend(faderId, assignOn);
              print("Assign send $faderId to current Mix: $assignOn");
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
                mainSendMixModel.updateControlGroup(muteGroupId, type, muteOn);
              }
              break;
            case 0x0D:
              final muteGroupId = dspPacket.param2;
              final assignOn = dspPacket.value == 1;
              mainSendMixModel.updateControlGroupAssignment(
                  muteGroupId, ControlGroupType.muteGroup, faderId, assignOn);
              break;
            case 0x16:
              final dcaGroupId = faderId - 205;
              final type = ControlGroupType.dca;
              final muteOn = dspPacket.value != 0;
              mainSendMixModel.updateControlGroup(dcaGroupId, type, muteOn);
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
              mainSendMixModel.updateControlGroupAssignment(
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

void faderChanged(int id, double valueInDb) {
  if (_socket == null || _currentMixIndex == -1) {
    return;
  }
  final value = ((valueInDb + 128.0) * 256.0).toInt();
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

void muteOnChanged(int id, bool muteOn) {
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

void _requestSceneState() {
  if (_socket == null) {
    return;
  }
  // request scene state
  _socket.add(_buildSystemPacket(0x04, [0x02, 0x00]));
}

void mixSelectChanged(int mixId, int mixIndex) {
  if (_socket == null) {
    return;
  }
  _currentMixIndex = -1;
  // Request current scene state
  // - to receive latest send levels for new mix
  // - to receive latest new mix master fader level
  _requestSceneState();

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
  _currentMixIndex = mixIndex;
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

void close() {
  _socket?.destroy();
}

void _onError(e) {
  print(e);
}
