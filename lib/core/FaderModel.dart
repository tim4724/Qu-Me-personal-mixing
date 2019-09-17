import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:qu_me/io/network.dart' as network;
import 'package:qu_me/widget/fader.dart';

class FaderModel extends ChangeNotifier {
  static final FaderModel _instance = FaderModel._internal();

  factory FaderModel() => _instance;

  // These are in range from -180.0 to +10.0
  final _valuesInDb = List.filled(60, 0.0);

  // These are in range from 0.0 to 1.0
  final _sliderValues = List.filled(60, 0.0);

  FaderModel._internal();

  double getValueInDb(int id) {
    return _valuesInDb[id];
  }

  double getSliderValue(int id) {
    return _sliderValues[id];
  }

  void onNewFaderValue(int id, double valueInDb) {
    _valuesInDb[id] = valueInDb;
    _sliderValues[id] = _convertToSliderValue(valueInDb);
    notifyListeners();
  }

  void onNewSliderValue(int id, double sliderValue) {
    sliderValue = sliderValue.clamp(0, 1);
    _sliderValues[id] = sliderValue;
    _valuesInDb[id] = _convertFromSliderValue(sliderValue);
    notifyListeners();
    network.faderChanged(id, _valuesInDb[id]);
  }

  double _convertToSliderValue(double levelDb) {
    const rangeInDb = FaderSlider.rangeInDb;
    const sliderValues = FaderSlider.sliderValues;
    for (var i = 1; i < rangeInDb.length; i++) {
      if (levelDb >= rangeInDb[i - 1] && levelDb < rangeInDb[i]) {
        final dif = rangeInDb[i] - rangeInDb[i - 1];
        double t = (levelDb - rangeInDb[i - 1]) / dif;
        return lerpDouble(sliderValues[i - 1], sliderValues[i], t);
      }
    }
    return 1;
  }

  double _convertFromSliderValue(double sliderPos) {
    const rangeInDb = FaderSlider.rangeInDb;
    const sliderValues = FaderSlider.sliderValues;
    for (var i = 1; i < sliderValues.length; i++) {
      if (sliderPos >= sliderValues[i - 1] && sliderPos < sliderValues[i]) {
        final dif = sliderValues[i] - sliderValues[i - 1];
        double t = (sliderPos - sliderValues[i - 1]) / dif;
        return lerpDouble(rangeInDb[i - 1], rangeInDb[i], t);
      }
    }
    return 1;
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
 *
 */
