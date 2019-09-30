import 'dart:io';

import 'package:qu_me/core/model/metersModel.dart';

void listen(RawDatagramSocket socket) {
  final metersModel = MetersModel();
  socket.listen(
    (e) {
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
          metersModel.onNewMeterLevel(id, meterDb);
        }
        metersModel.notifyListeners(); // TODO fix
      }
    },
    onError: (e) {
      print(e);
    },
    onDone: () {
      print("Meter socket closed");
    },
    cancelOnError: false,
  );
  // todo update last contact of mixer object
}

int _getUint16(List<int> data, [int index = 0]) {
  return data[index] | data[index + 1] << 8;
}
