import 'dart:ui';

import 'package:qu_me/widget/fader.dart';

double convertFromDbValue(double levelDb) {
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

double convertToDbValue(double levelQuMeUi) {
  const rangeInDb = FaderSlider.rangeInDb;
  const sliderValues = FaderSlider.sliderValues;
  for (var i = 1; i < sliderValues.length; i++) {
    if (levelQuMeUi >= sliderValues[i - 1] && levelQuMeUi < sliderValues[i]) {
      final dif = sliderValues[i] - sliderValues[i - 1];
      double t = (levelQuMeUi - sliderValues[i - 1]) / dif;
      return lerpDouble(rangeInDb[i - 1], rangeInDb[i], t);
    }
  }
  return 0;
}
