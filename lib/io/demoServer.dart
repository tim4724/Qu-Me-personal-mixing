import 'dart:io';

ServerSocket _serverSocket;

Future startDemoServer() async {
  await stopDemoSocket();
  return _startDemoServer();
}

Future _startDemoServer() async {
  return ServerSocket.bind(InternetAddress.anyIPv4, 51326).then((serverSocket) {
    _serverSocket = serverSocket;
    _serverSocket.listen(handleClient);
  });
}

void handleClient(Socket client) {
  if (client.remoteAddress.isLoopback) {
    client.add([10]);
  } else {
    client.close();
  }
}

Future stopDemoSocket() async {
  await _serverSocket?.close();
  _serverSocket = null;
}
