import 'dart:async';
import 'dart:convert';
import 'dart:io';

RawDatagramSocket _udpSocket;

Stream<List<int>> findQuMixers() {
  final streamController = new StreamController<List<int>>();
  RawDatagramSocket.bind(InternetAddress.anyIPv4, 0).then((socket) {
    _udpSocket?.close();
    _udpSocket = socket;
    final data = ascii.encode('QU Find');
    final broadcastAddress = InternetAddress('255.255.255.255');
    final port = 51320;

    socket.broadcastEnabled = true;
    final t = Timer.periodic(Duration(seconds: 1), (t) {
      socket.send(data, broadcastAddress, port);
    });
    socket.listen(
      (e) {
        final dg = socket.receive();
        if (dg != null) {
          streamController.add(dg.data);
        }
      },
      onError: (e) {
        print(e);
      },
      onDone: () {
        t.cancel();
        streamController.close();
        print("udp socket closed");
      },
      cancelOnError: false,
    );
  });
  return streamController.stream;
}

void stop() {
  _udpSocket?.close();
  _udpSocket = null;
}
