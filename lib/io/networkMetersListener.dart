import 'dart:async';
import 'dart:io';

import 'package:qu_me/core/model/metersModel.dart';

Timer _timer;
RawDatagramSocket _datagramSocket;

Future<int> getPort() async {
  if (_datagramSocket == null) {
    _datagramSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    // TODO: maybe should start listening here?
  }
  return _datagramSocket.port;
}

void start(InternetAddress address, int port) async {
  _timer?.cancel();
  _timer = Timer.periodic(Duration(seconds: 1), (t) {
    _datagramSocket.send([0x7f, 0x25, 0x00, 0x00], address, port);
    // TODO: listen for close...
  });
  _listen(_datagramSocket);
}

bool isRunning() {
  return _timer?.isActive;
}

void stop() {
  _datagramSocket.close();
  _datagramSocket = null;
  _timer?.cancel();
  _timer = null;
}

void _listen(RawDatagramSocket socket) {
  socket.listen(
    (RawSocketEvent e) {
      final dg = socket.receive();
      if (dg == null) {
        return;
      }
      final packet = dg.data;
      if (packet[0] == 0x7f && packet.length > 2) {
        final groupId = packet[1];
        // final len = _getUint16(dg.data, 2);
        // 0x35 = sends?
        // 0x36 = mixes
        // 0x38 = ?????

        int id;
        int lastId;
        if (groupId == 0x23) {
          id = 0;
          lastId = 38;
        } else if (groupId == 0x24) {
          id = 39;
          lastId = 60;
        } else {
          // ????
          return;
        }

        // TODO use correct meter source (post-preamp, post-eq, post-comp, ...)

        final data = packet.sublist(4);
        for (var offset = 10;
            offset < data.length && id < lastId;
            offset += 20, id++) {
          final meter = _getUint16(data, offset);
          // TODO range is -110 to +10
          final meterDb = (meter / 256.0 - 128.0);
          MetersModel.levelsInDb[id] = meterDb;
        }
        MetersModel.notifyStreamListeners();
      }
    },
    onError: (e) {
      // TODO: do something
      print(e);
    },
    onDone: () {
      // TODO: do something
      print("Meter socket closed");
    },
    cancelOnError: false,
  );
  // todo update last contact of mixer object
}

int _getUint16(List<int> data, [int index = 0]) {
  return data[index] | data[index + 1] << 8;
}
