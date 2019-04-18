import 'dart:io';

Socket _socket;

void connect() {
  Socket.connect("192.168.13.15", 455).then((socket) {
    _socket = socket;
    socket.listen(
      (data) => {

      },
      onDone: _onDone,
      onError: _onError,
    );
  });
}

bool sendCommand(List<int> data) {
  if(_socket != null) {
    _socket.add(data);
    return true;
  }
  return false;
}

void _onDone(){
  if(_socket != null) {
    _socket.destroy();
    _socket = null;
  }
}

void _onError(e) {
  print(e);
}