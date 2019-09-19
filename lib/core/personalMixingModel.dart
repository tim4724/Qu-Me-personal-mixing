import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:qu_me/entities/mix.dart';
import 'package:qu_me/entities/scene.dart';
import 'package:qu_me/entities/send.dart';
import 'package:qu_me/io/network.dart' as network;

import 'faderModel.dart';

class MixingModel extends ChangeNotifier {
  static final MixingModel _instance = MixingModel._internal();

  factory MixingModel() => _instance;

  Scene _scene;
  final _sendsByGroup = List.filled(4, List<Send>());
  final _groupNames = ["Group 1", "Group 2", "Group 3", "Me"];
  Mix currentMix;

  MixingModel._internal();

  void onScene(Scene scene) {
    _scene = scene;
    _sendsByGroup[0] = _scene.sends;

    // TODO let user select
    currentMix = availableMixes[0];

    FaderModel faderModel = FaderModel();
    if(currentMix != null) {
      for (int i = 0; i < currentMix.sendLevelsInDb.length; i++) {
        faderModel.onNewFaderLevel(i, currentMix.sendLevelsInDb[i]);
      }
    } else {
      faderModel.reset();
    }
    for(int i = 0; i < scene.mixesLevelInDb.length; i++) {
      faderModel.onNewFaderLevel(i + 39, scene.mixesLevelInDb[i]);
    }
    notifyListeners();
  }

  void onMixSelected(int index) {
    currentMix = _scene.mixes[index];
    network.mixSelectChanged();
    notifyListeners();
  }

  List<Send> getSendsForGroup(int index) {
    return UnmodifiableListView(_sendsByGroup[index]);
  }

  String getNameForGroup(int index) {
    return _groupNames[index];
  }

  bool get initialized => _scene != null;

  List<Send> get availableSends => UnmodifiableListView(_scene.sends);

  List<Mix> get availableMixes => UnmodifiableListView(_scene.mixes);

  void reset() {
    _scene = null;
    notifyListeners();
  }
}
