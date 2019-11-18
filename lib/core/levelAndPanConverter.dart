import 'dart:ui';

const _rangeInDb = [-128, -50, -30, -10, 0, 10];
const _sliderValues = [0.0, 0.125, 0.25, 0.5, 0.75, 1.0];
// TODO use function

double dBLevelToSliderValue(double dBLevel) {
  dBLevel = dBLevel.clamp(-128.0, 10.0);
  for (var i = 1; i < _rangeInDb.length; i++) {
    if (dBLevel >= _rangeInDb[i - 1] && dBLevel <= _rangeInDb[i]) {
      final dif = _rangeInDb[i] - _rangeInDb[i - 1];
      double t = (dBLevel - _rangeInDb[i - 1]) / dif;
      return lerpDouble(_sliderValues[i - 1], _sliderValues[i], t)
          .clamp(0.0, 1.0);
    }
  }
  return 1;
}

double dbLevelFromSliderValue(double sliderLevel) {
  sliderLevel = sliderLevel.clamp(0.0, 1.0);
  for (var i = 1; i < _sliderValues.length; i++) {
    if (sliderLevel >= _sliderValues[i - 1] &&
        sliderLevel <= _sliderValues[i]) {
      final dif = _sliderValues[i] - _sliderValues[i - 1];
      double t = (sliderLevel - _sliderValues[i - 1]) / dif;
      return lerpDouble(_rangeInDb[i - 1], _rangeInDb[i], t)
          .clamp(-128.0, 10.0);
    }
  }
  return 0;
}

double panToSliderValue(int pan) {
  return pan.clamp(0, 74).toDouble() / 74.0;
}

int panFromSliderValue(double sliderPan) {
  return (sliderPan * 74.0).toInt().clamp(0, 74);
}
