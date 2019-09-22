import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:qu_me/entities/mixer.dart';
import 'package:qu_me/io/network.dart' as network;

class ConnectionModel extends ChangeNotifier {
  static final ConnectionModel _instance =
      ConnectionModel._internal();

  factory ConnectionModel() => _instance;

  Mixer _mixer;

  ConnectionModel._internal();

  void onStartConnect(String name, InternetAddress address) {
    _mixer = Mixer(name, address);
    network.connect(name, address);
    notifyListeners();
  }

  void onMixerVersion(int type, String firmware) {
    _mixer.mixerType = type;
    _mixer.firmwareVersion = firmware;
    notifyListeners();
  }

  InternetAddress get remoteAddress => _mixer?.address;

  String get name => _mixer?.name;

  get type => _mixer?.mixerType;

  bool get initialized {
    return _mixer?.mixerType != null;
  }

  void reset() {
    _mixer?.mixerType = null;
    notifyListeners();
  }
}
