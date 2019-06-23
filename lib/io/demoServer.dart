import 'dart:io';

ServerSocket _serverSocket;

Future startDemoServer() async {
  await _serverSocket?.close();
  return _startDemoServer();
}

Future _startDemoServer() async {
  return ServerSocket.bind(InternetAddress.anyIPv4, 51325).then((serverSocket) {
    _serverSocket = serverSocket;
    _serverSocket.listen(handleClient);
  });
}

void handleClient(Socket client) {
  if (client.remoteAddress.isLoopback) {
    client.add([10]);
  }
  client.close();
}

void stopDemoSocket() {
  _serverSocket?.close();
  _serverSocket = null;
}
