import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:qu_me/core/levelConverter.dart';
import 'package:qu_me/core/model/mainSendMixModel.dart';
import 'package:qu_me/io/network.dart' as network;

// TODO is performance good for many listeners?
class FaderLevelModel extends ChangeNotifier {
  static final FaderLevelModel _instance = FaderLevelModel._internal();

  factory FaderLevelModel() => _instance;

  // These are in range from -inf to +10.0
  // -128.0 equals "-inf" as far as the qu mixer is concerned
  // However the level in this model can go lower than -128.0
  // The reason is to keep the proportion between sends the same
  // if trim reduces the level
  final _levelsInDb = List.filled(60, -128.0);

  // These are in range from 0.0 to 1.0 and
  // are related to fader position in the ui
  final _sliderValues = List.filled(60, 0.0);

  final mixingModel = MainSendMixModel();
  final _dirtySends = Set<int>();
  Timer _networkNotifyTimer;

  FaderLevelModel._internal();

  double getValueInDb(int id) {
    return _levelsInDb[id];
  }

  double getSliderValue(int id) {
    return _sliderValues[id];
  }

  void onNewFaderLevel(int id, double levelInDb) {
    _levelsInDb[id] = levelInDb.clamp(-128.0, 10.0);
    _sliderValues[id] = convertFromDbValue(levelInDb);
    notifyListeners();
  }

  static final maxDbValue = convertToDbValue(1.0);

  void onTrim(List<int> sendIds, double delta) {
    if (sendIds == null || sendIds.length == 0 || delta == 0) {
      return;
    }

    double maxSendLevel = 0.0;
    for (final sendId in sendIds) {
      final sendLevel = _sliderValues[sendId];
      if (sendLevel > maxSendLevel) {
        maxSendLevel = sendLevel;
      }
    }

    // One fader reached the top. Do not increase trim anymore
    if (delta > 0 && maxSendLevel >= 1.0) {
      return;
    }

    final newMaxSendLevel = (maxSendLevel + delta).clamp(0.0, 1.0);
    // Delta in db for all sends will be calculated based on the
    // delta for the highest send level
    final deltaInDb =
        convertToDbValue(newMaxSendLevel) - convertToDbValue(maxSendLevel);

    for (final sendId in sendIds) {
      // If 2 Faders are linked. Only change 1 fader
      if (mixingModel.getSend(sendId).faderLinked && sendId % 2 == 1) {
        continue;
      }
      _levelsInDb[sendId] = (_levelsInDb[sendId] + deltaInDb);
      _sliderValues[sendId] = convertFromDbValue(_levelsInDb[sendId]);
      _dirtySends.add(sendId);
    }
    notifyListeners();
    notifyNetwork();
  }

  void onNewSliderValue(int id, double sliderValue) {
    sliderValue = sliderValue.clamp(0.0, 1.0);
    _sliderValues[id] = sliderValue;
    _levelsInDb[id] = convertToDbValue(sliderValue);
    _dirtySends.add(id);
    notifyListeners();
    notifyNetwork();
  }

  void reset() {
    for (int i = 0; i < _levelsInDb.length; i++) {
      _levelsInDb[i] = -128.0;
      _sliderValues[i] = 0.0;
    }
    notifyListeners();
  }

  void notifyNetwork() {
    // do not spam the qu mixer with messages
    if (_networkNotifyTimer == null || !_networkNotifyTimer.isActive) {
      final minInterval = (_dirtySends.length ~/ 8 + 1) * 5;
      _networkNotifyTimer = Timer(Duration(milliseconds: minInterval), () {
        for (var id in _dirtySends) {
          network.faderChanged(id, _levelsInDb[id].clamp(-128.0, 10.0));
        }
        _dirtySends.clear();
        _networkNotifyTimer = null;
      });
    }
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
