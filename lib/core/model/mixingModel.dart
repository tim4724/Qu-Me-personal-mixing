import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:qu_me/core/model/connectionModel.dart';
import 'package:qu_me/entities/faderInfo.dart';
import 'package:qu_me/entities/mix.dart';
import 'package:qu_me/entities/mixer.dart';
import 'package:qu_me/entities/scene.dart';
import 'package:qu_me/entities/send.dart';
import 'package:qu_me/io/network.dart' as network;

import 'faderLevelModel.dart';

class MixingModel extends ChangeNotifier {
  static final MixingModel _instance = MixingModel._internal();

  factory MixingModel() => _instance;

  final _allMixes = List<Mix>();
  final currentMix = ValueNotifier<Mix>(null);

  final _sendValueNotifierForId = List<ValueNotifier<Send>>();
  final _availableSends = List<int>();

  bool _initialized = false;

  MixingModel._internal();

  void onScene(Scene scene) {
    print("onScene");

    _allMixes.clear();
    _allMixes.addAll(scene.mixes);

    if (currentMix.value == null) {
      // TODO let user select
      currentMix.value = _allMixes[0];
    }

    _sendValueNotifierForId.length = scene.sends.length;
    for (final send in scene.sends) {
      if (_sendValueNotifierForId[send.id] == null) {
        _sendValueNotifierForId[send.id] = ValueNotifier<Send>(null);
      }
      _sendValueNotifierForId[send.id].value = send;
    }

    _availableSends.clear();
    // TODO: What if Mixerconnection is not initialized
    // TODO: Parse which sends are assigned anyway
    if (ConnectionModel().type == MixerType.QU_16) {
      for (Send send in scene.sends) {
        if (currentMix.value.sendAssigns[send.id] &&
            (send.sendType != SendType.monoChannel || send.id < 16)) {
          _availableSends.add(send.id);
        }
      }
    } else {
      // TODO improve
      for (Send send in scene.sends) {
        _availableSends.add(send.id);
      }
    }
    // TODO update sendsBmemberNameyGroup

    FaderLevelModel faderModel = FaderLevelModel();
    if (currentMix != null) {
      for (int i = 0; i < currentMix.value.sendLevelsInDb.length; i++) {
        faderModel.onNewFaderLevel(i, currentMix.value.sendLevelsInDb[i]);
      }
    } else {
      faderModel.reset();
    }
    for (int i = 0; i < scene.mixesLevelInDb.length; i++) {
      faderModel.onNewFaderLevel(i + 39, scene.mixesLevelInDb[i]);
    }
    _initialized = true;
    notifyListeners();
  }

  void selectMix(int id) {
    final index = id - _allMixes[0].id;
    currentMix.value = _allMixes[index];
    network.mixSelectChanged(currentMix.value.id, index);
    notifyListeners();
  }

  Send getSend(int id) {
    return _sendValueNotifierForId[id].value;
  }

  void updateNotifier() {}

  bool get initialized => _initialized;

  List<int> get availableSends => UnmodifiableListView(_availableSends);

  List<Mix> get availableMixes => UnmodifiableListView(_allMixes);

  void reset() {
    _initialized = false;
    _allMixes.clear();
    _availableSends.clear();
    notifyListeners();
  }

  ValueNotifier<Send> getNotifier(int sendId) {
    return _sendValueNotifierForId[sendId];
  }

  void setSendName(int sendId, String name) {
    Send newSend = _sendValueNotifierForId[sendId].value.copyWith(name: name);
    _sendValueNotifierForId[sendId].value = newSend;
  }
}
