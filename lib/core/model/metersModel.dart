import 'dart:async';

class MetersModel {
  MetersModel._internal();

  // These are in range from -110.0 to +10.0
  static final levelsInDb = List.filled(60, -110.0);

  static final _meterChangesController =
      StreamController<List<double>>(sync: true);
  static final stream = _meterChangesController.stream.asBroadcastStream();

  static void notifyStreamListeners() {
    _meterChangesController.add(levelsInDb);
  }
}
