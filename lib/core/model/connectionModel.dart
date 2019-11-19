import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:qu_me/entities/mixer.dart';
import 'package:qu_me/io/network.dart' as network;

class ConnectionModel extends ChangeNotifier {
  static final ConnectionModel _instance = ConnectionModel._internal();

  factory ConnectionModel() => _instance;

  Mixer _mixer;
  bool _initialized = false;

  ConnectionModel._internal();

  void startConnect(String name, InternetAddress address) {
    _mixer = Mixer(name, address);
    _initialized = false;
    network.connect(name, address);
    notifyListeners();
  }

  void onMixerVersion(int type, String firmware) {
    _mixer.mixerType = type;
    _mixer.firmwareVersion = firmware;
    notifyListeners();
  }

  void onLoadingScene() {
    _initialized = false;
    notifyListeners();
  }

  void onSceneLoaded() {
    _initialized = true;
    notifyListeners();
  }

  InternetAddress get remoteAddress => _mixer?.address;

  String get name => _mixer?.name;

  int get type => _mixer?.mixerType;

  bool get initialized {
    return _initialized;
  }

  void reset() {
    _mixer = null;
    _initialized = false;
    notifyListeners();
  }
}
