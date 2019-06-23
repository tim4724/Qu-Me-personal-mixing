import 'dart:async';
import 'dart:io';

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

void _connect(InternetAddress address, Function onConnected, Function onError) {
  Socket.connect(address, 51325, timeout: Duration(seconds: 1)).then((socket) {
    _socket = socket;
    onConnected();
    socket.listen(
      (data) {
        _streamController.add(data);
      },
      onDone: _onDone,
      onError: _onError,
    );
  }).catchError((a) {
    onError();
  });
}

void send(int i) {
  _socket.add([i]);
}

void _onDone() {
  _socket?.destroy();
  _socket = null;
}

void _onError(e) {
  print(e);
}
