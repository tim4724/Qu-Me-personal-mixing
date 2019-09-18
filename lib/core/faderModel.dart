import 'package:flutter/widgets.dart';
import 'package:qu_me/io/network.dart' as network;

import 'levelConverter.dart';

class FaderModel extends ChangeNotifier {
  static final FaderModel _instance = FaderModel._internal();

  factory FaderModel() => _instance;

  // These are in range from -128.0 to +10.0
  final _levelsInDb = List.filled(60, -128.0);

  // These are in range from 0.0 to 1.0
  final _sliderValues = List.filled(60, 0.0);

  FaderModel._internal();

  double getValueInDb(int id) {
    return _levelsInDb[id];
  }

  double getSliderValue(int id) {
    return _sliderValues[id];
  }

  void onNewFaderLevel(int id, double levelInDb) {
    _levelsInDb[id] = levelInDb;
    _sliderValues[id] = convertFromDbValue(levelInDb);
    notifyListeners();
  }

  void onNewSliderValue(int id, double sliderValue) {
    sliderValue = sliderValue.clamp(0.0, 1.0);
    _sliderValues[id] = sliderValue;
    _levelsInDb[id] = convertToDbValue(sliderValue);
    notifyListeners();
    network.faderChanged(id, _levelsInDb[id]);
  }
}

/**
 * 0 channel 1
 * 1 channel 2
 * 32 ST1
 * 33 ST2
 * 34 ST3
 * 35 FX Ret 1
 * 36 FX Ret 2
 * 37 FX Ret 3
 * 38 FX Ret 4
 * 39 Mix 1 Master
 * 40 Mix 2 Master
 * 41 Mix 3 Master
 * 42 Mix 4 Master
 * 43 Mix 5/6
 * 45 Mix 7/8
 * 47 Mix 9/10
 * 49 Main?
 *
 */
