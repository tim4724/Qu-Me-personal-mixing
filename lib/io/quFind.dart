import 'dart:async';
import 'dart:convert';
import 'dart:io';

RawDatagramSocket _udpSocket;

void findQuMixers(FoundCallback foundCallback) async {
  _udpSocket?.close();
  _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  final socket = _udpSocket;

  final broadcastAddress = InternetAddress('255.255.255.255');
  final port = 51320;
  final data = ascii.encode('QU Find');
  socket.broadcastEnabled = true;
  socket.send(data, broadcastAddress, port);

  print("QU Find start");
  final t = Timer.periodic(Duration(seconds: 1), (t) {
    socket.send(data, broadcastAddress, port);
  });


  socket.listen(
    (e) {
      final dg = socket.receive();
      if (dg != null) {
        final name = ascii.decode(dg.data);
        foundCallback(name, dg.address, DateTime.now());
      }
    },
    onError: (e) {
      print(e);
    },
    onDone: () {
      t.cancel();
      print("QU Find _socket closed");
    },
    cancelOnError: false,
  );
}

typedef FoundCallback = Function(
    String name, InternetAddress address, DateTime time);

void stop() {
  _udpSocket?.close();
  _udpSocket = null;
}
