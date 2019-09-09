import 'dart:async';
import 'dart:io';

Timer _timer;

void start(RawDatagramSocket socket, InternetAddress address, int port) {
  _timer?.cancel();
  _timer = Timer.periodic(Duration(seconds: 1), (t) {
    socket.send([0x7f, 0x25, 0x00, 0x00], address, port);
  });

  // TODO: what us the response
  // Random data?

  // todo update last contact of mixer object
}

bool isRunning() {
  return _timer?.isActive;
}

void stop() {
  _timer?.cancel();
  _timer = null;
}
