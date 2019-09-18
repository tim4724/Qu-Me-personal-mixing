import 'package:flutter/widgets.dart';

import 'levelConverter.dart';

class MetersModel extends ChangeNotifier {
  static final MetersModel _instance = MetersModel._internal();

  factory MetersModel() => _instance;

  MetersModel._internal();

  // These are in range from -110.0 to +10.0
  final _levelsInDb = List.filled(60, -110.0);

  int get levelCount => _levelsInDb.length;

  double getMeterValue(int id) {
    return convertFromDbValue(_levelsInDb[id]);
  }

  void onNewMeterLevel(int id, double levelInDb) {
    _levelsInDb[id] = levelInDb;
  }
}
