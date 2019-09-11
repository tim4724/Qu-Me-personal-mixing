import 'dart:async';
import 'dart:convert';
import 'dart:io';

RawDatagramSocket _udpSocket;

void findQuMixers(FoundCallback foundCallback) {
  _udpSocket?.close();

  RawDatagramSocket.bind(InternetAddress.anyIPv4, 0).then((socket) {
    _udpSocket = socket;
    final data = ascii.encode('QU Find');
    final broadcastAddress = InternetAddress('255.255.255.255');
    final port = 51320;

    socket.broadcastEnabled = true;
    socket.send(data, broadcastAddress, port);
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
        print("QU Find socket closed");
      },
      cancelOnError: false,
    );
  });
}

typedef FoundCallback = Function(
    String name, InternetAddress address, DateTime time);

void stop() {
  _udpSocket?.close();
  _udpSocket = null;
}
