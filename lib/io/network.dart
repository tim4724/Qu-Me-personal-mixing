import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:qu_me/core/sceneParser.dart' as sceneParser;
import 'package:qu_me/entities/mixer.dart';
import 'package:qu_me/io/demoServer.dart' as demoServer;
import 'package:qu_me/io/heartbeat.dart' as heartbeat;

Socket _socket;
final StreamController _streamController = StreamController();
final Stream stream = _streamController.stream.asBroadcastStream();

void connect(Mixer mixer, Function onConnected, Function onError) {
  if (mixer.address.isLoopback) {
    demoServer.startDemoServer().then((a) {
      _connect(mixer, onConnected, onError);
    });
  } else {
    _connect(mixer, onConnected, onError);
  }
}

void _connect(final Mixer mixer, Function onConnected, Function onError) async {
  final checkInitDone = () {
    if (onConnected != null && mixer.isReady()) {
      onConnected(mixer);
      onConnected = null;
    }
  };

  _socket?.destroy();
  _socket = await Socket.connect(mixer.address, 51326);
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
    },
    onError: _onError,
    cancelOnError: false,
  );

  // TODO: init timeout?!

  // TODO: Init in heartbeat class?
  final heartbeatSocket =
      await RawDatagramSocket.bind(InternetAddress.ANY_IP_V4, 0);

  // request meters? or Request remote heartbeat port?
  // is it really "requestMeters" ?
  // Group Id 0x00 -> "QU-You"?
  _socket.add(_buildSystemPacket(0x00, _fromUint16(heartbeatSocket.port)));
  // request mixer version
  _socket.add(_buildSystemPacket(0x04, [0x00, 0x00]));
  // request scene state
  _socket.add(_buildSystemPacket(0x04, [0x02, 0x00]));

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
            heartbeat.start(heartbeatSocket, mixer.address, dstPort);
            checkInitDone();
            break;
          case 0x01:
            mixer.mixerType = data[0];
            mixer.firmwarVersion =
                "${data[1]}.${data[2]}-${_getUint16(data, 4)}";
            checkInitDone();
            break;
          case 0x06:
            mixer.scene = sceneParser.parse(data);
            checkInitDone();
            break;
          default:
            print("unknown packet group id: $groupId");
            break;
        }
        break;

      case 0xF7:
        // DSP packet (always 9 bytes)
        final packet = await queue.take(9); // or take 8 ???
        print("received dsp packet: $packet");
        break;
      default:
        print("unexpected type: $type");
    }
  }
}

Uint8List _buildSystemPacket(int groupId, List<int> value) {
  return [0x7f, groupId, value.length, value.length >> 8]..addAll(value);
}

int _getUint16(Uint8List data, [int index = 0]) {
  return data[index] | data[index + 1] << 8;
}

Uint8List _fromUint16(int value) {
  return Uint8List.fromList([value | value << 8]);
}

void send(int i) {
  _socket?.add([i]);
  _socket?.flush()?.then((a) {
    _streamController.add([i]);
  });
}

void _onError(e) {
  print(e);
}
