import 'dart:ui';

const _rangeInDb = [-128, -50, -30, -10, 0, 10];
const _sliderValues = [0.0, 0.125, 0.25, 0.5, 0.75, 1.0];
// TODO use function

double convertFromDbValue(double levelDb) {
  for (var i = 1; i < _rangeInDb.length; i++) {
    if (levelDb >= _rangeInDb[i - 1] && levelDb < _rangeInDb[i]) {
      final dif = _rangeInDb[i] - _rangeInDb[i - 1];
      double t = (levelDb - _rangeInDb[i - 1]) / dif;
      return lerpDouble(_sliderValues[i - 1], _sliderValues[i], t);
    }
  }
  return 1;
}

double convertToDbValue(double levelQuMeUi) {
  for (var i = 1; i < _sliderValues.length; i++) {
    if (levelQuMeUi > _sliderValues[i - 1] && levelQuMeUi <= _sliderValues[i]) {
      final dif = _sliderValues[i] - _sliderValues[i - 1];
      double t = (levelQuMeUi - _sliderValues[i - 1]) / dif;
      return lerpDouble(_rangeInDb[i - 1], _rangeInDb[i], t);
    }
  }
  return 0;
}
