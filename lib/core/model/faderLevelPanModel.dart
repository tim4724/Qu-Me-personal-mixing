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
  final _levelsInDb = List.filled(46, -128.0);

  // These are in range from 0.0 to 1.0 and
  // are related to fader position in the ui
  final _levelSlider = List.filled(46, 0.0);

  // Only the 39 sends can be panned
  // These are in range from 0.0 to 1.0
  // 0: panned to the left, 0.5: center, 1: panned to the right
  final _panSlider = List.filled(39, 0.5);

  // Only the 32 mono channels can be linked
  final _levelLinked = List.filled(32, false);
  final _panLinked = List.filled(32, false);

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

  void initLevels(List<double> levelInDb, [int offset = 0]) {
    for (int i = 0; i < levelInDb.length; i++) {
      onLevel(i + offset, levelInDb[i]);
    }
  }

  void initPans(List<int> pans) {
    for (int i = 0; i < pans.length; i++) {
      onPan(i, pans[i]);
    }
  }

  void onSliderLevel(int id, double sliderValue) {
    // If two channels are linked, always go for the even channels' data
    if (_isUnEven(id) && _isLevelLinked(id)) {
      id--;
    }
    sliderValue = sliderValue.clamp(0.0, 1.0);
    _levelSlider[id] = sliderValue;
    _levelsInDb[id] = dbLevelFromSliderValue(sliderValue);
    _levelController.add(id);
    _dirtyNetworkLevelIds.add(id);
    _notifyNetwork();
  }

  void onSliderPan(int id, double sliderValue) {
    // If two channels are linked, always go for the even channels' data
    if (_isUnEven(id) && _isPanLinked(id)) {
      id--;
      sliderValue = 1.0 - sliderValue;
    }
    _panSlider[id] = sliderValue.clamp(0.0, 1.0);
    _panController.add(id);
    _dirtyNetworkPanIds.add(id);
    _notifyNetwork();
  }

  void onTrim(List<int> sendIds, double delta) {
    if (sendIds == null || sendIds.isEmpty || delta == 0.0) {
      return;
    }

    final maxSendId = maxBy(sendIds, (id) => _levelSlider[id]);
    double maxSendLevel = _levelSlider[maxSendId];
    // One fader reached the top or all faders reached the bottom.
    // Do not decrease trim anymore
    if (delta > 0 && maxSendLevel >= 1.0 || delta < 0 && maxSendLevel <= 0.0) {
      return;
    }

    final newMaxSendLevelSlider = (maxSendLevel + delta).clamp(0.0, 1.0);
    final newMaxSendLevelDb = dbLevelFromSliderValue(newMaxSendLevelSlider);
    // Delta in db for all sends will be calculated based on the
    // delta for the highest send level
    final deltaInDb = newMaxSendLevelDb - _levelsInDb[maxSendId];

    for (int i = 0; i < sendIds.length; i++) {
      int id = sendIds[i];
      // TODO: check what happens on the mixer if both faders are trimmed...
      if (_isUnEven(id) && _isLevelLinked(id)) {
        // If two channels are linked, always set the even channel
        id--;
        if (i > 0 && sendIds[i - 1] == id) {
          // Already set the even channel
          // This assumes the send id list is sorted the both linked channels
          // are next to each other in the sendIds-list
          continue;
        }
      }
      final newLevelInDb = (_levelsInDb[id] + deltaInDb);
      _levelsInDb[id] = newLevelInDb;
      _levelSlider[id] = dBLevelToSliderValue(newLevelInDb);
      _levelController.add(id);
      _dirtyNetworkLevelIds.add(id);
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

  Stream<double> getLevelStreamForId(final int id) {
    final bool unEvenId = _isUnEven(id);
    return _levelStream.transform(StreamTransformer<int, double>.fromHandlers(
      handleData: (int value, EventSink<double> sink) {
        // If two channels are linked, always go for the even channels' data
        if (unEvenId && _isLevelLinked(id) ? value == id - 1 : value == id) {
          sink.add(_levelSlider[value]);
        }
      },
    ));
  }

  Stream<double> getPanStreamForId(final int id) {
    final bool unEvenId = _isUnEven(id);
    return _panStream.transform(StreamTransformer<int, double>.fromHandlers(
      handleData: (int value, EventSink<double> sink) {
        if (unEvenId && _isPanLinked(id)) {
          // If two channels are linked, always go for the even channels' data
          if (value == id - 1) {
            sink.add(1.0 - _panSlider[value]);
          }
        } else if (value == id) {
          sink.add(_panSlider[value]);
        }
      },
    ));
  }

  double getLevelSLider(int id) {
    if (_isUnEven(id) && _isLevelLinked(id)) {
      // If two channels are linked, always go for the even channel' data
      return _levelSlider[id - 1];
    }
    return _levelSlider[id];
  }

  double getPanSlider(int id) {
    if (_isUnEven(id) && _isPanLinked(id)) {
      // If two channels are linked, always go for the even channels' data
      return 1.0 - _panSlider[id - 1];
    }
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

  void _notifyNetwork() {
    // do not spam the qu mixer with messages
    if (_networkNotifyTimer == null || !_networkNotifyTimer.isActive) {
      final minInterval = (_dirtyNetworkLevelIds.length ~/ 8 + 1) * 5;
      _networkNotifyTimer = Timer(Duration(milliseconds: minInterval), () {
        for (int id in _dirtyNetworkLevelIds) {
          // the level in db can go lower than -128.0 => clamp the value
          network.changeFaderLevel(id, _levelsInDb[id].clamp(-128.0, 10.0));
        }
        _dirtyNetworkLevelIds.clear();
        for (int id in _dirtyNetworkPanIds) {
          network.changeFaderPan(id, panFromSliderValue(_panSlider[id]));
        }
        _dirtyNetworkPanIds.clear();
      });
    }
  }

  bool _isLevelLinked(int id) {
    return id >= 0 && id < _levelLinked.length && _levelLinked[id];
  }

  bool _isPanLinked(int id) {
    return id >= 0 && id < _panLinked.length && _panLinked[id];
  }

  static bool _isUnEven(int i) {
    return i % 2 == 1;
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
