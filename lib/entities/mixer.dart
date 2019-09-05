import 'dart:io';

class Mixer {
  String name;
  InternetAddress address;
  DateTime discoveredDate;

  Mixer(this.name, this.address, [this.discoveredDate]) {
    if (discoveredDate == null) {
      discoveredDate = DateTime.now();
    }
  }
}
