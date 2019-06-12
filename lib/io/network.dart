import 'dart:async';
import 'dart:io';

Socket _socket;
final StreamController _streamController = StreamController()..addStream(Stream<int>.empty());
final Stream stream = _streamController.stream.asBroadcastStream();

void connect() {
  Socket.connect("192.168.13.15", 455).then((socket) {
    _socket = socket;
    socket.listen(
      (data) => {_streamController.add(data)},
      onDone: _onDone,
      onError: _onError,
    );
  });
}

void send(int i) {
  _streamController.add(i);
  // _socket.add([i]);
}

void _onDone() {
  _socket?.destroy();
  _socket = null;
}

void _onError(e) {
  print(e);
}
