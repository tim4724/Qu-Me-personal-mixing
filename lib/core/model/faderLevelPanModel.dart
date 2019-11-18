import 'dart:async';

import 'package:collection/collection.dart';
import 'package:qu_me/core/levelAndPanConverter.dart';
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
  final _panSlider = List.filled(60, 0.5); // TODO: or 39?

  final _levelLinked = List.filled(60, false); // TODO: or 39? or 32?
  final _panLinked = List.filled(60, false); // TODO: or 39? or 32?

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
  }

  void initLinks(List<bool> levelLinks, List<bool> panLinks) {
    for (int i = 0; i < levelLinks.length; i++) {
      _levelLinked[i] = levelLinks[i];
      _panLinked[i] = panLinks[i];
    }
  }

  void initLevelsAndPans(List<double> levelInDb, List<int> pans) {
    for (int i = 0; i < levelInDb.length; i++) {
      onLevel(i, levelInDb[i]);
    }
    for (int i = 0; i < pans.length; i++) {
      onPan(i, pans[i]);
    }
  }

  void onSliderLevel(int id, double sliderValue) {
    sliderValue = sliderValue.clamp(0.0, 1.0);
    _levelSlider[id] = sliderValue;
    _levelsInDb[id] = dbLevelFromSliderValue(sliderValue);
    _levelController.add(id);
    _dirtyNetworkLevelIds.add(id);
    _notifyNetwork();
  }

  void onSliderPan(int id, double sliderValue) {
    _panSlider[id] = sliderValue.clamp(0.0, 1.0);
    _panController.add(id);
    _dirtyNetworkPanIds.add(id);
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
    final deltaInDb = dbLevelFromSliderValue(newMaxSendLevel) -
        dbLevelFromSliderValue(maxSendLevel);

    for (int i = 0; i < sendIds.length; i++) {
      int sendId = sendIds[i];
      if (_levelLinked[sendId] &&
          sendId % 2 == 1 &&
          i > 0 &&
          sendIds[i - 1] == sendId - 1) {
        // If two channels are linked and both are to be trimmed,
        // only change the lower ("left") one
        // The mixer will automatically change the other one
        // This assumes the send id list is sorted the both linked channels
        // are next to each other in the sendIds-list
        continue;
      }
      final newLevelInDb = (_levelsInDb[sendId] + deltaInDb);
      _levelsInDb[sendId] = newLevelInDb;
      _levelSlider[sendId] = dBLevelToSliderValue(newLevelInDb);
      _levelController.add(sendId);
      _dirtyNetworkLevelIds.add(sendId);
    }
    _notifyNetwork();
  }

  void onLink(int id, bool link, bool panLink) {
    assert(panLink == false || link == panLink);
    // Always 2 channels that are next to each other are linked
    id -= id % 2;
    _levelLinked.fillRange(id, id + 1, link);
    _panLinked.fillRange(id, id + 1, panLink);
    // TODO: Ensure that Level and pan is set correct for both of the linked channels...
  }

  void onLevel(int id, double levelInDb) {
    _levelsInDb[id] = levelInDb.clamp(-128.0, 10.0);
    _levelSlider[id] = dBLevelToSliderValue(levelInDb);
    _levelController.add(id);
  }

  void onPan(int id, int pan) {
    _panSlider[id] = panToSliderValue(pan);
    _panController.add(id);
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

  void reset() {
    _levelsInDb.fillRange(0, _levelsInDb.length, -128.0);
    _levelSlider.fillRange(0, _levelSlider.length, 0.0);
    for (int i = 0; i < _levelsInDb.length; i++) {
      _levelController.add(i);
    }
    _panSlider.fillRange(0, _panSlider.length, 0.5);
    for (int i = 0; i < _panSlider.length; i++) {
      _panController.add(i);
    }
    _levelLinked.fillRange(0, _levelLinked.length, false);
    _panLinked.fillRange(0, _panLinked.length, false);
    _dirtyNetworkPanIds.clear();
    _dirtyNetworkLevelIds.clear();
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
        for (int id in _dirtyNetworkLevelIds) {
          // the level in db can go lower than -128.0 => clamp the value
          network.faderLevelChanged(id, _levelsInDb[id].clamp(-128.0, 10.0));
        }
        _dirtyNetworkLevelIds.clear();
        for (int id in _dirtyNetworkPanIds) {
          network.faderPanChanged(id, panFromSliderValue(_panSlider[id]));
        }
        _dirtyNetworkPanIds.clear();
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
