import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';
import 'package:qu_me/io/demoServer.dart' as demoServer;

Socket _socket;
final StreamController _streamController = StreamController();
final Stream stream = _streamController.stream.asBroadcastStream();

void connect(InternetAddress address, Function onConnected, Function onError) {
  if (address.isLoopback) {
    demoServer.startDemoServer().then((a) {
      _connect(address, onConnected, onError);
    });
  } else {
    _connect(address, onConnected, onError);
  }
}

void _connect(
    InternetAddress address, Function onConnected, Function onError) async {
  _socket?.close();

  final host = InternetAddress.anyIPv4;
  final heartBeatSocket = await RawDatagramSocket.bind(host, 0);
  final udpPort = heartBeatSocket.port;
  final requestMetersPacket = [0x7f, 0x00, 0x02, 0x00, udpPort, udpPort >> 8];

  _socket = await Socket.connect(address, 51326, timeout: Duration(seconds: 5));
  _socket.setOption(SocketOption.tcpNoDelay, true);
  onConnected();
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
      byteStreamController.close();
    },
    onError: _onError,
    cancelOnError: false,
  );
  StreamQueue<int> queue = StreamQueue(byteStreamController.stream);

  // request meters
  _socket.add(requestMetersPacket);

  while (true) {
    int type = await queue.peek;
    switch (type) {
      case 0x7F:
        // System packet
        final header = await queue.lookAhead(4);
        final len = header[3] << 8 & header[2];
        final packet = await queue.take(len);
        print("received system packet: $packet");
        break;

      case 0xF7:
        // DSP packet (always 9 bytes)
        final packet = await queue.take(9);
        print("received dsp packet: $packet");
        break;
      default:
        print("unexpected type: $type");
    }
  }
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
