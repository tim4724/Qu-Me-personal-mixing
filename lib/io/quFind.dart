import 'dart:async';
import 'dart:convert';
import 'dart:io';

RawDatagramSocket _udpSocket;

void findQuMixers(MixerFoundListener listener) async {
  _udpSocket?.close();
  _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  final socket = _udpSocket;
  socket.broadcastEnabled = true;
  final broadcastAddress = InternetAddress('255.255.255.255');
  final port = 51320;
  final data = ascii.encode('QU Find');

  print("QU Find: start");
  final t = Timer.periodic(Duration(seconds: 1), (t) {
    socket.send(data, broadcastAddress, port);
  });
  socket.listen(
    (RawSocketEvent e) {
      final dg = socket.receive();
      if (dg != null) {
        final name = ascii.decode(dg.data);
        listener.onMixerFound(name, dg.address, DateTime.now());
      }
    },
    onError: (e) {
      print("QU Find: socket error");
      print(e);
    },
    onDone: () {
      t.cancel();
      print("QU Find: socket closed");
    },
    cancelOnError: false,
  );
}

abstract class MixerFoundListener {
  void onMixerFound(String name, InternetAddress address, DateTime time);
}

void stop() {
  _udpSocket?.close();
  _udpSocket = null;
}
