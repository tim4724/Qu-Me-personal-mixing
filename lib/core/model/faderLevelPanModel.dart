import 'dart:async';

import 'package:collection/collection.dart';
import 'package:qu_me/core/levelConverter.dart';
import 'package:qu_me/core/model/mainSendMixModel.dart';
import 'package:qu_me/io/network.dart' as network;

class FaderLevelPanModel {
  static final FaderLevelPanModel _instance = FaderLevelPanModel._internal();

  factory FaderLevelPanModel() => _instance;

  // These are in range from -inf to +10.0
  // -128.0 equals "-inf" as far as the qu mixer is concerned
  // However the level in this model can go lower than -128.0
  // The reason is to keep the proportion between sends the same
  // if trim reduces the level of a group of sends
  final _levelsInDb = List.filled(60, -128.0);

  // These are in range from 0.0 to 1.0 and
  // are related to fader position in the ui
  final _levelSlider = List.filled(60, 0.0);

  // These are in range from 0.0 to 1.0
  // 0: panned to the left, 0.5: center, 1: panned to the right
  final _panSlider = List.filled(60, 0.5);

  final _levelController = StreamController<int>(sync: true);
  final _panController = StreamController<int>(sync: true);
  final _dirtyNetworkLevelIds = Set<int>();
  final _dirtyNetworkPanIds = Set<int>();
  Stream<int> _levelStream;
  Stream<int> _panStream;
  Timer _networkNotifyTimer;

  FaderLevelPanModel._internal() {
    _levelStream = _levelController.stream.asBroadcastStream();
    _panStream = _panController.stream.asBroadcastStream();
    _levelStream.listen((id) => _dirtyNetworkLevelIds.add(id));
    _panStream.listen((id) => _dirtyNetworkPanIds.add(id));
  }

  void onNewLevelSlider(int id, double sliderValue) {
    sliderValue = sliderValue.clamp(0.0, 1.0);
    _levelSlider[id] = sliderValue;
    _levelsInDb[id] = convertToDbValue(sliderValue);
    _levelController.add(id);
    _notifyNetwork();
  }

  void onTrim(List<int> sendIds, double delta) {
    if (sendIds == null || sendIds.length == 0 || delta == 0) {
      return;
    }

    final maxSendId = maxBy(sendIds, (id) => _levelSlider[id]);
    double maxSendLevel = _levelSlider[maxSendId];

    // One fader reached the top. Do not increase trim anymore
    if (delta > 0 && maxSendLevel >= 1.0) {
      return;
    }

    final newMaxSendLevel = (maxSendLevel + delta).clamp(0.0, 1.0);
    // Delta in db for all sends will be calculated based on the
    // delta for the highest send level
    final deltaInDb =
        convertToDbValue(newMaxSendLevel) - convertToDbValue(maxSendLevel);

    final _mainSendMixModel = MainSendMixModel();
    for (final sendId in sendIds) {
      // If 2 Faders are linked. Only change 1 fader
      if (_mainSendMixModel.getSend(sendId).faderLinked && sendId % 2 == 1) {
        continue;
      }
      _levelsInDb[sendId] = (_levelsInDb[sendId] + deltaInDb);
      _levelSlider[sendId] = convertFromDbValue(_levelsInDb[sendId]);
      _levelController.add(sendId);
    }
    _notifyNetwork();
  }

  void onNewPanSlider(int id, double sliderValue) {
    sliderValue = sliderValue.clamp(0.0, 1.0);
    _panSlider[id] = sliderValue;
    _panController.add(id);
    _notifyNetwork();
  }

  void onNewFaderLevel(int id, double levelInDb) {
    _levelsInDb[id] = levelInDb.clamp(-128.0, 10.0);
    _levelSlider[id] = convertFromDbValue(levelInDb);
    _levelController.add(id);
  }

  void reset() {
    for (int i = 0; i < _levelsInDb.length; i++) {
      _levelsInDb[i] = -128.0;
      _levelSlider[i] = 0.0;
      _panSlider[i] = 0.5;
      _levelController.add(i);
    }
    _dirtyNetworkPanIds.clear();
    _dirtyNetworkLevelIds.clear();
  }

  Stream<double> getLevelStreamForId(int id) {
    return _getStreamForId(id, _levelStream, _levelSlider);
  }

  Stream<double> getPanStreamForId(int id) {
    return _getStreamForId(id, _panStream, _panSlider);
  }

  double getLevelSLider(int id) {
    return _levelSlider[id];
  }

  double getPanSlider(int id) {
    return _panSlider[id];
  }

  double getLevelInDb(int id) {
    return _levelsInDb[id];
  }

  Stream<double> _getStreamForId(int id, Stream source, List<double> values) {
    return source.transform(StreamTransformer<int, double>.fromHandlers(
      handleData: (int value, EventSink<double> sink) {
        if (value == id) {
          sink.add(values[id]);
        }
      },
    ));
  }

  void _notifyNetwork() {
    // do not spam the qu mixer with messages
    if (_networkNotifyTimer == null || !_networkNotifyTimer.isActive) {
      final minInterval = (_dirtyNetworkLevelIds.length ~/ 8 + 1) * 5;
      _networkNotifyTimer = Timer(Duration(milliseconds: minInterval), () {
        for (var id in _dirtyNetworkLevelIds) {
          network.faderChanged(id, _levelsInDb[id].clamp(-128.0, 10.0));
        }
        // TODO: pans?!
        _dirtyNetworkLevelIds.clear();
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
