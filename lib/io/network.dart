import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:hex/hex.dart';
import 'package:qu_me/core/FaderModel.dart';
import 'package:qu_me/core/MixerConnectionModel.dart';
import 'package:qu_me/core/PersonalMixingModel.dart';
import 'package:qu_me/core/sceneParser.dart' as sceneParser;
import 'package:qu_me/io/demoServer.dart' as demoServer;
import 'package:qu_me/io/heartbeat.dart' as heartbeat;

Socket _socket;

void connect(String name, InternetAddress address, Function onError) {
  MixerConnectionModel().onStartConnect(name, address);

  if (address.isLoopback) {
    demoServer.startDemoServer().then((a) {
      _connect(address, onError);
    });
  } else {
    _connect(address, onError);
  }
}

void _connect(InternetAddress address, Function onError) async {
  final mixerModel = MixerConnectionModel();
  final mixingModel = MixingModel();
  final faderModel = FaderModel();

  _socket = await Socket.connect(address, 51326);
  _socket.setOption(SocketOption.tcpNoDelay, true);

  final byteStreamController = StreamController<int>();
  _socket.listen(
    (dataEvent) {
      for (final byte in dataEvent) {
        byteStreamController.add(byte);
      }
    },
    onDone: () {
      print("Socket was closed");
      _socket.destroy();
      heartbeat.stop();
      byteStreamController.close();
      mixerModel.reset();
      mixingModel.reset();
    },
    onError: _onError,
    cancelOnError: false,
  );

  // TODO: init timeout?!

  // TODO: Init in heartbeat class?
  final heartbeatSocket =
      await RawDatagramSocket.bind(InternetAddress.ANY_IP_V4, 0);

  // request meters? or Request remote heartbeat port?
  // Group Id 0x00 -> "QU-You"?
  _socket.add(_buildSystemPacket(0x00, _fromUint16(heartbeatSocket.port)));
  // request mixer version
  _socket.add(_buildSystemPacket(0x04, [0x00, 0x00]));
  // request scene state
  _socket.add(_buildSystemPacket(0x04, [0x02, 0x00]));

  // Check default password (aka is no password set)
  _socket.add(_buildSystemPacket(0x04, HEX.decode("01040000090e6490")));

  // Listen for Mix 1 Master Fader
  _socket.add(_buildSystemPacket(0x04, HEX.decode("0327")));
  _socket.add(_buildSystemPacket(
      0x04,
      HEX.decode(
          "130000000000000080000000000000000000000000000000000000000000000000000000")));

  // Listen for Mix 1 Sends Faders
  _socket.add(_buildSystemPacket(0x04, HEX.decode("0427")));
  _socket.add(_buildSystemPacket(
      0x04,
      HEX.decode(
          "140000000100000000000000000000000000000000000000000000000000000000000000")));

  // Check password "inear"
  _socket.add(_buildSystemPacket(0x04, HEX.decode("0104000046c340f4")));

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
            heartbeat.start(heartbeatSocket, _socket.remoteAddress, dstPort);
            break;
          case 0x01:
            mixerModel.onMixerVersion(
                data[0], "${data[1]}.${data[2]}-${_getUint16(data, 4)}");
            break;
          case 0x06:
            mixingModel.onScene(sceneParser.parse(Uint8List.fromList(data)));
            break;
          case 0x02:
            if (data[0] == 4 && data[1] == 0) {
              print("password incorrect");
            } else if (data[0] == 4 && data[1] == 1) {
              print("password correct");
            }
            break;
          case 0x07:
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

        if (dspPacket.targetGroup == 4 &&
            (dspPacket.valueId == 0x0a || dspPacket.valueId == 0x07)) {
          // valueId == 0x0a for send fader
          // valueId == 0x07 for master fader
          print("Fader value: ${dspPacket.value}");
          final valueInDb =
              (dspPacket.value / 256.0 - 128.0).clamp(-128.0, 10.0);
          faderModel.onNewFaderValue(dspPacket.param1, valueInDb);
        }
        break;

      default:
        print("unexpected type: $type");
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
  final value = ((valueInDb + 128) * 256.0).toInt();
  final valueId = id < 39 ? 0x0a : 0x07;
  final param2 = id < 39 ? 0x00 : 0x07;
  final packet = [
    0x7F,
    0x03,
    0x08,
    0x00,
    0x04,
    0x04,
    valueId,
    0x00,
    id,
    param2
  ];
  packet.addAll(_fromUint16(value));
  _socket.add(packet);
  print("Send Fader: $packet");
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

void _onError(e) {
  print(e);
}
