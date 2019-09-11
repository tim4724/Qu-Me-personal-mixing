import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:qu_me/entities/mix.dart';
import 'package:qu_me/entities/scene.dart';
import 'package:qu_me/entities/send.dart';
import 'package:rxdart/rxdart.dart';

class MixingModel extends ChangeNotifier {
  static final MixingModel _instance = MixingModel._internal();

  factory MixingModel() => _instance;

  Scene _scene;
  final _sendsByGroup = List.filled(4, List<Send>());

  MixingModel._internal();

  void onScene(Scene scene) {
    _scene = scene;
    _sendsByGroup[0] = _scene.sends;
    notifyListeners();
  }

  List<Send> getForGroup(int index) {
    return UnmodifiableListView(_sendsByGroup[index]);
  }

  bool get initialized => _scene != null;

  List<Send> get availableSends => UnmodifiableListView(_scene.sends);

  List<Mix> get availableMixes => UnmodifiableListView(_scene.mixes);

  void reset() {
    _scene = null;
    _sendsByGroup.forEach((e) => e.clear());
    notifyListeners();
  }
}
