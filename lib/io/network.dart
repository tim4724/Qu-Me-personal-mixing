import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:hex/hex.dart';
import 'package:qu_me/core/connectionModel.dart';
import 'package:qu_me/core/faderModel.dart';
import 'package:qu_me/core/mixingModel.dart';
import 'package:qu_me/core/sceneParser.dart' as sceneParser;
import 'package:qu_me/entities/mixer.dart';
import 'package:qu_me/entities/scene.dart';
import 'package:qu_me/io/heartbeat.dart' as heartbeat;
import 'package:qu_me/io/metersListener.dart' as metersListener;

Socket _socket;
int _currentMixIndex = -1;

void connect(String name, InternetAddress address) async {
  if (address.isLoopback) {
    final mixerModel = ConnectionModel();
    mixerModel.onMixerVersion(MixerType.QU_16, "0");
    final mixingModel = MixingModel();
    mixingModel.onScene(buildDemoScene());
  } else {
    _connect(address);
  }
}

void _connect(InternetAddress address) async {
  final mixerModel = ConnectionModel();
  final mixingModel = MixingModel();
  final faderModel = FaderModel();

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
      mixerModel.reset();
      mixingModel.reset();
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
            mixerModel.onMixerVersion(
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
            mixingModel.onScene(sceneParser.parse(Uint8List.fromList(data)));
            break;
          case 0x07:
            // Don't know what this is...
            print("group id: $groupId; dataLen: $dataLen");
            print("data: $data");
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
            case 0x07:
              final valueInDb = (dspPacket.value / 256.0 - 128.0);
              faderModel.onNewFaderLevel(faderId, valueInDb);
              print("Fader value: ${dspPacket.value}");
              break;
            case 0x06:
              final muteOn = dspPacket.value == 1;
              print("Mute fader $faderId: $muteOn");
              break;
            case 0x09:
              final assignOn = dspPacket.value == 1;
              print("Assign send $faderId to current Mix: $assignOn");
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
